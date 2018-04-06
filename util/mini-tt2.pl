#!/usr/bin/env perl

use v5.10.1;
use strict;
use warnings;

use File::Temp qw( tempfile );
use File::Copy qw( move );
use File::Compare qw( compare );
use File::Spec ();
use Getopt::Std qw( getopts );

sub usage ($);
sub replace_tt2_var ($$);
sub is_prev_line ($);
sub check_line_continuer_in_macro_raw_line ($);
sub fix_line_continuer_in_macro_line ($$$);

my $var_with_init_pat = qr/(\**) \b [_a-zA-Z]\w* (?: :\d+ )? \s*
                           (?: = \s* \w+ )?/x;

my %opts;
getopts "hs:d:", \%opts or usage(1);

if ($opts{h}) {
    usage(0);
}

my $subsys = $opts{s}
    or die "No -s SUBSYS option specified.\n";

if ($subsys !~ /^(?:http|stream)$/) {
    die "Bad subsystem name: $subsys (expecting either http or stream)\n";
}

my %tt2_vars;
{
    $tt2_vars{subsys} = $subsys;

    my $SUBSYS = uc $subsys;

    $tt2_vars{SUBSYS} = $SUBSYS;

    my ($req_type, $req_subsys);
    if ($subsys eq 'http') {
        $req_type = 'ngx_http_request_t';
        $req_subsys = 'http';

    } else {
        $req_type = 'ngx_stream_lua_request_t';
        $req_subsys = 'stream_lua';
    }

    $tt2_vars{req_type} = $req_type;
    $tt2_vars{req_subsys} = $req_subsys;
    $tt2_vars{"${subsys}_subsys"} = 1;

    if ($subsys eq 'http') {
        $tt2_vars{log_prefix} = "";

    } else {
        $tt2_vars{log_prefix} = "$subsys "
    }
}

my $infile = shift
    or die "No tt2 input file specified.\n";

if ($infile !~ /\.tt2$/i) {
    die "Input file name does not end with .tt2: $infile";
}

my $outdir = $opts{d};
if (!$outdir) {
    die "No -d OUTDIR option specified.\n";
}

if (!-d $outdir) {
    die "Output directory $outdir does not exist.\n";
}

(my $outfile = $infile) =~ s/\.tt2$//i;
$outfile =~ s{.*[/\\]}{}g;
$outfile =~ s/^ngx_subsys_/ngx_${subsys}_/g;
$outfile = File::Spec->catfile($outdir, $outfile);

#warn "outfile: $outfile";

open my $in, $infile
    or die "Cannot open $infile for reading: $!\n";

my ($out, $tmpfile) = tempfile "$subsys-XXXXXXX", TMPDIR => 1;

my ($raw_line, $skip);
my ($prev_var_decl, $prev_raw_var_col);
my ($continued_func_call, $func_name, $func_prefix_len_diff, $func_indent_len);
my ($func_raw_prefix_len);
my ($in_if, $in_else, $if_branch_hit);
my ($in_block, $block, %blocks);
my (%ctl_cmds, $prev_continuing_macro_line);

print $out <<_EOC_;

/*
 * !!! DO NOT EDIT DIRECTLY !!!
 * This file was automatically generated from the following template:
 *
 * $infile
 */

_EOC_

while (<$in>) {
    if (/\s+\n$/) {
        die "$infile: line $.: unexpected line-trailing spaces found: $_";
    }

    if (m{\[\%-|-\%\]}) {
        die "$infile: line $.: - modifier not supported; we manage ",
            "whitespaces automatically anyway.\n";
    }

    if (/^ \s* \[\%\# .*? \%\] \s* $/x) {
        next;
    }

    my $raw_line = $_;

    if (/^ \s* \[\% \s* BLOCK \s+ (\w+) \s* \%\] \s* $/x) {
        my $block_name = $1;

        #die "BLOCK name: $block_name";

        if ($in_block) {
            die "$infile: line $.: nested BLOCK directives not supported.\n";
        }

        if ($in_else) {
            die "$infile: line $.: BLOCK directive cannot be used inside an ",
                "ELSE branch defined on line $in_else.\n";
        }

        if ($in_if) {
            die "$infile: line $.: BLOCK directive cannot be used inside an ",
                "IF or ELSIF branch defined on line $in_if.\n";
        }

        $in_block = $.;

        my $prev_block = $blocks{$block_name};
        if (defined $prev_block) {
            die "$infile: line $.: duplicated definition of BLOCK $block_name ",
                "(previous definition was on line $prev_block->{line}).\n";
        }

        $block = {
            name => $block_name,
            line => $.,
            txt => '',
        };

        $blocks{$block_name} = $block;

        #warn "added block with name $block_name: $block";

        next;
    }

    if (/^ \s* \[\% \s* ((?:ELS)?IF) \s+ (.*?) \%\] \s* $/x) {
        my $keywd = $1;
        my $cond = $2;

        if ($keywd eq 'IF') {
            if ($in_if || $in_else) {
                die "$infile: line $.: nested IF not supported yet\n";
            }

        } else {   # beging 'ELSIF'
            if ($in_else) {
                die "$infile: line $.: unexpected ELSIF after ELSE defined on ",
                    "line $in_else\n";
            }
        }

        $in_if = $.;
        $ctl_cmds{$.} = 1;

        $cond =~ s/\s+$//;

        if ($cond =~ /^ (\w+) \s* == \s* (?: (['"]) (.*?) \2 | (\d+) )
            \s* (?:\#.*?)? $/x)
        {
            my $var = $1;
            my $v = $3 // $4;

            if ($var eq 'subsys' && $v !~ /^(?:http|stream)$/) {
                die "$infile: line $.: bad subsystem value to be compared: ",
                    "$v\n";
            }

            if ($v eq $tt2_vars{$var}) {
                $if_branch_hit = 1;
                undef $skip;

            } else {
                $skip = 1;
            }

        } elsif ($cond =~ /^ (\w+) $/x) {
            my $var = $1;

            if ($var =~ /^ (?: subsys | req_type | req_subsys | SUBSYS ) $/ix) {
                die "$infile: line $.: variable $var is always true: ",
                    "$tt2_vars{$var}.\n";
            }

            if ($tt2_vars{$var}) {
                $if_branch_hit = 1;
                undef $skip;

            } else {
                $skip = 1;
            }

        } else {
            die "$infile: line $.: unknnown $keywd condition: $cond\n";
        }

        next;
    }

    if (/^ \s* \[\% \s* ELSE \s* (?:\# .*?) \%\] \s* $/x) {
        if ($in_else) {
            die "$infile: line $.: already seen ELSE directive on line ",
                "$in_else.\n";
        }

        $ctl_cmds{$.} = 1;

        if ($if_branch_hit) {
            $skip = 1;

        } else {
            undef $skip;
            $if_branch_hit = 1;
        }

        next;
    }

    if (/^ \s* \[\% \s* END \s* (?:\# .*?)? \%\] \s* $/x) {
        if (!$in_if && !$in_else && !$in_block) {
            die "$infile: line $.: lingering END directive; no IF, ELSIF, ",
                "ELSE, or BLOCK directive seen earlier.\n";
        }

        $ctl_cmds{$.} = 1;

        if ($in_if) {
            undef $in_if;
            undef $in_else;
            undef $skip;
            undef $if_branch_hit;
            next;
        }

        if ($in_block) {
            undef $in_block;
            $block = undef;
            next;
        }

        die "Cannot reach here";
    }

    next if $skip;

    if (/^ \s* \[\% \s* (?: SET \s* )? (\w+) \s* =
           \s* (?: (['"]) (.*?) \2 | (\d+) ) \s* \%\] \s* $/x)
    {
        $ctl_cmds{$.} = 1;

        if ($in_block) {
            die "$infile: line $.: assignments not allowed inside BLOCK ",
                "$block->{name} ",
                "defined on line $block->{line}.\n";
        }

        my ($var, $str_v, $num_v) = ($1, $3, $4);
        $tt2_vars{$var} = $str_v // $num_v;
        next;
    }

    if (/^ \s* \[\% \s* (INCLUDE|PROCESS) \s+ (\w+) \s* \%\] \s*$/x) {
        my ($cmd, $block_name) = ($1, $2);

        if ($in_block) {
            die "$infile: line $.: directive $cmd not allowed inside BLOCK ",
                "$block->{name} ",
                "defined on line $block->{line}.\n";
        }

        my $blk = $blocks{$block_name};
        if (!defined $blk) {
            die "$infile: line $.: BLOCK $block_name not defined (yet).\n";
        }

        #warn "OUT: $blk->{txt}";

        print $out $blk->{txt};
        next;
    }

    s/\[\% \s* (['"]) (.*?) \1 \s* \%\]/$2/egx;
    s/\[\% \s* (.*?) \%\]/replace_tt2_var($1, $.)/egx;

    my $indent_len = 0;

    if (/^(\s+)/m) {
        my $indent = $1;
        if ($indent =~ /\t/) {
            die "$infile: line $.: use of tabs in indentation\n";
        }
        if ($indent =~ /([^ \n])/m) {
            die "$infile: line $.: use of non-space chars in indentation: ",
                ord($1), "\n";
        }
        $indent_len = length $indent;
    }

    my $passthrough;

    # check local variable declaration and struct member declaration alignment

    if (m{^ (\s+) ([_a-zA-Z]\w*) \b (\s*) $var_with_init_pat
           (?: \s* , \s* $var_with_init_pat )* \s* ; \s*
           (?: /\* .*? \*/ \s* )? $}x
        && $2 !~ /^(?:goto|return)$/)
    {
        my ($indent, $type, $padding, $pointer) = ($1, $2, $3, $4);

        my $padding_len = length $padding;
        my $var_col = length($indent) + length($type) + $padding_len
                      + length($pointer);

        if ($raw_line !~ /^ ( \s+ (?: \w+ | \[\% .*? \%] )+
                            (?: \s* \*+ | \s+ ) ) /x)
        {
            die "$infile: line $.: failed to match raw line for variable ",
                "declaration: $_";
        }

        my $raw_var_col = length $1;

        my $var_col_diff = $raw_var_col - $var_col;

        if ($var_col_diff > 0) {
            $_ = $indent . $type . $padding . (" " x $var_col_diff)
                . $pointer . substr $_, $var_col;
            #warn "NEW: $_";
        }

        if ($var_col_diff < 0) {
            #warn "HIT a var declaration (col $var_col): $raw_line";
            #warn "line $.: raw var column: $raw_var_col (diff: $var_col_diff)";

            my $diff = -$var_col_diff;
            if ($diff >= $padding_len) {
                die "$infile: line $.: existing padding ($padding_len spaces) ",
                    "not enough to compensate the variable name alignment ",
                    "requirement ($diff difference).\n";
            }

            $_ = $indent . $type . (" " x ($padding_len - $diff))
                . $pointer . substr $_, $var_col;
            #warn "NEW: $_";
        }

        #if ($var_col_diff != 0) {
            #warn "HIT a var declaration (col $var_col): $raw_line";
            #warn "line $.: raw var column: $raw_var_col (diff: $var_col_diff)";
        #}

        #warn "HIT: $_";

        if (defined $prev_var_decl && is_prev_line $prev_var_decl) {
            # check vertical alignment in the templates
            if ($prev_raw_var_col != $raw_var_col) {
                die "$infile: $.: variable declaration or struct/enum ",
                    "member declarations' identifiers not aligned ",
                    "vertically: $_";
            }
        }

        $prev_var_decl = $.;
        $prev_raw_var_col = $raw_var_col;

        undef $continued_func_call;
        $passthrough = 1;
    }

    # check function calls spanning multiple lines

    if ($continued_func_call) {
        my $terminated;
        if (/^(\s*)\S/m) {
            my $indent = $1;
            if (length $indent <= $func_indent_len) {
                #warn "terminating since indent is smaller";
                $terminated = 1;
            }

        } elsif (/^\s*$/) {
            #warn "terminating due to empty line";
            $terminated = 1;
        }

        if ($terminated) {
            undef $continued_func_call;
            undef $func_prefix_len_diff;
            undef $func_indent_len;
            undef $func_name;
        }
    }

    if ($continued_func_call) {
        my $skip_patching;

        if ($raw_line =~ /^ (\s*) /x) {
            my $raw_len = length $1;
            #warn "raw len: $raw_len, raw prefix len: $func_raw_prefix_len";
            if ($raw_len != $func_raw_prefix_len) {
                die "$infile: line $.: continued arguments not aligned with ",
                    "the function call on line $continued_func_call.\n";
                $skip_patching = 1;
            }
        }

        unless ($skip_patching) {
            if ($func_prefix_len_diff > 0) {
                #warn "func len diff: $func_prefix_len_diff";
                if (!s/^ {$func_prefix_len_diff}//) {
                    die "$infile: line $.: failed to remove ",
                        "$func_prefix_len_diff spaces from the indentation ",
                        "of the continued lines for the function call ",
                        "$func_name defined on $continued_func_call.\n";
                }

            } else {
                $_ = (" " x -$func_prefix_len_diff) . $_;
            }

            my $ln_len = length;
            if (/\n$/) {
                $ln_len--;
            }

            my $excess = $ln_len - 80;
            if ($excess > 0) {
                #warn "line $.: line too long (len: ", length($_),
                #     ", excess: $excess)";
                if (!s/^ {$excess}//) {
                    die "$infile: line $.: failed to remove ",
                        "$excess spaces from the indentation ",
                        "of the continued lines for the function call ",
                        "$func_name defined on $continued_func_call.\n";
                }
                #warn "final length: ", length($_);
            }
        }

    } elsif (!$passthrough) {
        if (/^ ( (.*? \W) ([_a-zA-Z]\w*) \( ) .*? [^\s\{;] \s* $/x) {
            # found a function call
            my ($prefix, $indent);
            ($prefix, $indent, $func_name) = ($1, $2, $3);
            if ($prefix !~ /^\w+ /) {
                my $len = length $prefix;
                if ($raw_line =~ /^ (.*? \w \( ) /x) {
                    my $raw_len = length $1;
                    if ($prefix !~ m{^ (?: \# \s*(?!define) | \s* /\* )}x) {
                        #warn "line $.: found continued func call: $_";
                        $continued_func_call = $.;
                        $func_prefix_len_diff = $raw_len - $len;
                        $func_indent_len = length $indent;
                        $func_raw_prefix_len = $raw_len;
                    }
                }
            }
        }
    }

    # check macro line continuers (\)

    if (m{^ ( \# \s* [a-z]\w* .*? (\s*) ) \\ \s* $}x) {
        $prev_continuing_macro_line = 1;

        my $prefix_len = length $1;
        my $padding_len = length $2;

        check_line_continuer_in_macro_raw_line($raw_line);
        fix_line_continuer_in_macro_line($_, $prefix_len, $padding_len);

    } elsif (m{^ (\s+ .*? (\s*) ) \\ \s* $}x) {

        if ($prev_continuing_macro_line) {
            my $prefix_len = length $1;
            my $padding_len = length $2;

            check_line_continuer_in_macro_raw_line($raw_line);
            fix_line_continuer_in_macro_line($_, $prefix_len, $padding_len);
            #warn "HIT: $_";

        } else {
            die "$infile: line $.: unexpected continuing macro line: $_";
            #undef $prev_continuing_macro_line;
        }

    } elsif (defined $prev_continuing_macro_line) {
        undef $prev_continuing_macro_line;
    }

    if ($in_block) {
        #warn "adding txt to $block with name $block->{name}: $_";
        $block->{txt} .= $_;
        next;
    }

    print $out $_;
}

close $out;

close $in;

if (!-f $outfile || compare($tmpfile, $outfile) != 0) {
    move $tmpfile, $outfile
        or die "Failed to move $tmpfile into $outfile: $!\n";
}

sub replace_tt2_var ($$) {
    my ($var, $lineno) = @_;

    $var =~ s/\s+$//;

    if ($var =~ /^ (?: subsys \s* (?: \bFILTER\b | \| )
                   \s* upper | SUBSYS ) $/x)
    {
        return $tt2_vars{SUBSYS};
    }

    my $val = $tt2_vars{$var};
    if (defined $val) {
        return $val;
    }

    if ($var =~ /^[_A-Za-z]\w*$/) {
        die "$infile: line $.: undefined tt2 variable: $var\n";
    }

    die "$infile: line $.: unknown tt2 variable or expression: $var\n";
}

sub is_prev_line ($) {
    my $ln = shift;
    my $diff = $. - $ln;
    return 1 if $diff == 1;
    return undef if $diff < 1;

    while (++$ln != $.) {
        if (!$ctl_cmds{$ln}) {
            return undef;
        }
    }

    return 1;
}

sub check_line_continuer_in_macro_raw_line ($) {
    my $raw_line = shift;
    if ($raw_line =~ /(.*) \\ \s* $/x) {
        my $raw_prefix_len = length $1;
        if ($raw_prefix_len != 77) {
            die "$infile: line $.: the line continuer \\ is not on the ",
                "78th column: $_\n";
        }

    } else {
        die "$infile: line $.: failed to find trailing \\ in raw line: $_";
    }
}

sub fix_line_continuer_in_macro_line ($$$) {
    my ($line, $prefix_len, $padding_len) = @_;

    if ($prefix_len < 77) {
        # add more space padding

        my $diff = 77 - $prefix_len;
        if ($_[0] !~ s/\\\n$/(' ' x $diff) . "\\\n"/e) {
            die "Cannot happen";
        }

    } elsif ($prefix_len > 77) {
        my $diff = $prefix_len - 77;
        if ($diff >= $padding_len) {
            if ($_[0] !~ s/ {$diff}\\\n?$/\\\n/) {
                die "Cannot happen";
            }

        } else {
            die "$infile: $.: existing padding ($padding_len spaces) ",
                "not enough to compensate the macro line continuer ",
                "alignment on the 78th column.\n";
        }

    } else {
        #warn "HIT (prefix len: $prefix_len): $_";
    }
}

sub usage ($) {
    my $rc = shift;
    my $msg = <<_EOC_;
Usage:
    $0 -s SUBSYSTEM -d DIR TT2-FILE

Options:
    -d DIR              Specify the output directory.
    -h                  Print this help.
    -s subsystem        Specifies the subsystem name, either http or stream.
_EOC_
    if ($rc == 0) {
        print $msg;
        exit 0;
    }
    warn $msg;
    exit $rc;
}
