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
    $tt2_vars{subsys} = $tt2_vars{subsystem} = $subsys;

    my $SUBSYS = uc $subsys;

    $tt2_vars{SUBSYS} = $tt2_vars{SUBSYSTEM} = $SUBSYS;

    my ($req_type, $req_subsys);
    if ($subsys eq 'http') {
        $req_type = 'ngx_http_request_t';
        $req_subsys = 'http';

    } else {
        $req_type = 'ngx_stream_lua_request_t';
        $req_subsys = 'stream_lua';
    }

    $tt2_vars{req_type} = $req_type;
    $tt2_vars{req_subsys} = $tt2_vars{req_subsystem} = $req_subsys;
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
$outfile =~ s/^ngx_subsys(?:tem)?_/ngx_${subsys}_/g;
$outfile = File::Spec->catfile($outdir, $outfile);

#warn "outfile: $outfile";

open my $in, $infile
    or die "Cannot open $infile for reading: $!\n";

my ($out, $tmpfile) = tempfile "$subsys-XXXXXXX", TMPDIR => 1;

my $in_if;
my $in_else;
my %tested;
my $skip;
my $if_branch_hit;
my $in_block;
my $block;
my %blocks;
my $in_cmt;

while (<$in>) {
    if (/^ \s* \[\%\# .*? \%\] \s* $/x) {
        next;
    }

    if (/^ \s* \[\%-? \s* BLOCK \s+ (\w+) \s* -?\%\] \s* $/x) {
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

    if (/^ \s* \[\%-? \s* ((?:ELS)?IF) \s+ (.*?) -?\%\] \s* $/x) {
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

        if ($cond =~ /^ (\w+) \s* == \s* (?: (['"]) (.*?) \2 | (\d+) )
            \s* (?:\#.*?)? $/x)
        {
            my $var = $1;
            my $v = $3 // $4;

            if ($var =~ /^subsys(?:tem)?$/ && $v !~ /^(?:http|stream)$/) {
                die "$infile: line $.: bad subsystem value to be compared: $v\n";
            }

            $tested{$v} = 1;

            if ($v eq $tt2_vars{$var}) {
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

    if (/^ \s* \[\%-? \s* ELSE \s* (?:\# .*?) -?\%\] \s* $/x) {
        if ($in_else) {
            die "$infile: line $.: already seen ELSE directive on line ",
                "$in_else.\n";
        }

        if ($if_branch_hit) {
            $skip = 1;

        } else {
            undef $skip;
            $if_branch_hit = 1;
        }

        next;
    }

    if (/^ \s* \[\%-? \s* END \s* (?:\# .*?)? -?\%\] \s* $/x) {
        if (!$in_if && !$in_else && !$in_block) {
            die "$infile: line $.: lingering END directive; no IF, ELSIF, ",
                "ELSE, or BLOCK directive seen earlier.\n";
        }

        if ($in_if) {
            undef $in_if;
            undef $in_else;
            undef %tested;
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

    if (/^ \s* \[\%-? \s* (?: SET \s* )? (\w+) \s* =
           \s* (?: (['"]) (.*?) \2 | (\d+) ) \s* -?\%\] \s* $/x)
    {
        if ($in_block) {
            die "$infile: line $.: assignments not allowed inside BLOCK ",
                "$block->{name} ",
                "defined on line $block->{line}.\n";
        }

        my ($var, $str_v, $num_v) = ($1, $3, $4);
        $tt2_vars{$var} = $str_v // $num_v;
        next;
    }

    if (/^ \s* \[\%-? \s* (INCLUDE|PROCESS) \s+ (\w+) \s* -?\%\] \s*$/x) {
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

    s/\[%-? \s* (['"]) (.*?) \1 \s* -?\%\]/$2/egx;
    s/\[%-? \s* (.*?) -?\%\]/replace_tt2_var($1, $.)/egx;

    if ($in_block) {
        #warn "adding txt to $block with name $block->{name}: $_";
        $block->{txt} .= $_;
        next;
    }

    print $out $_;
}

close $out;

close $in;

if (-f $outfile && compare($tmpfile, $outfile) != 0) {
    move $tmpfile, $outfile
        or die "Failed to move $tmpfile into $outfile: $!\n";
}

sub replace_tt2_var ($$) {
    my ($var, $lineno) = @_;

    $var =~ s/\s+$//;

    if ($var =~ /^ (?: subsystem \s* (?: \bFILTER\b | \| )
                   \s* upper | SUBSYS ) $/x)
    {
        return $tt2_vars{SUBSYS};
    }

    my $val = $tt2_vars{$var};
    if (defined $val) {
        return $val;
    }

    if ($var =~ /^[A-Za-z]\w*$/) {
        return '';
    }

    die "$infile: line $.: unknown tt2 variable or expression: $var\n";
}

sub usage ($) {
    my $rc = shift;
    my $msg = <<_EOC_;
Usage:
    $0 -s SUBSYSTEM TT2-FILE

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
