# Name

meta-lua-nginx-module - templates and toolchains for generating
http-lua-nginx-module and stream-lua-nginx-module.

# Usage

```shell
$ make SUBSYS=stream DESTDIR=/path/to/stream-lua-nginx-module/src -j4
```

All make options are optional.

## Supported Options

| Option        | Meaning                                             | Default     |
| ------------- | --------------------------------------------------- | ----------- |
| SUBSYS        | Subsystem this build is for                         | `http`      |
| DESTDIR       | Directory the generated files should go             | `build/src` |

# Directory Structures
```
├── src: all source files
│   ├── http: http subsystem specific files, not rendered through the template engine
│   ├── stream: stream subsystem specific files, not rendered through the template engine
│   └── subsystem: templates file that are shared between subsystems, rendered the template engine
└── utils: build toolchains
```
# Developing
## General Workflow

First, determine where the change should goes to. As an example, if you would like to change
a file inside `lua-nginx-module`, that file could either be rendered through the template engine,
or be simply copied from the `src/http` directory as-is without going through the template engine.

To tell which one is the case, look at the first few lines of the generated file. A file rendered by
the template engine will have something like this:

```C
/*
 * !!! DO NOT EDIT, YOUR CHANGES WILL BE OVERWRITTEN !!!
 * Generated from: src/subsystem/ddebug.h.tt2
 */
```

Next, edit the file and use command similar to the following to build the new source code:

```shell
$ make SUBSYS=http DESTDIR=../lua-nginx-module/src -j4
```

Next, update the tests inside the respective repository. In this case, they will be under `../lua-nginx-module/t`.

Finally, create PR for both the `meta-lua-nginx-module` and `lua-nginx-module`.

## Template Features

All the files under `src/subsystem` are valid [Perl TT2](http://www.template-toolkit.org) files and should be able
to be rendered using the `mini-tt2.pl` tool inside this repo, the [lemplate](https://github.com/openresty/lemplate)
or the official [Perl TT2](http://www.template-toolkit.org) renderer.

**Note:** The `mini-tt2.pl` tool has been specifically tailored for rendering C source codes and will reformat
to make sure the rendered file follows the general styling guidelines of NGINX. Rendering using other TT2 compatible
should yield files that can be built successfully but not necessarily style wise correct.

In general, you should always use the `mini-tt2.pl` tool while working with this repository and only submit
files rendered by it to `lua-nginx-module` and `stream-lua-nginx-module`. You should also avoid using any TT2 features
that the `mini-tt2.pl` tool does not support unless there is a very good reason to do so.

The `mini-tt2.pl` tool supports the following subset of TT2 features:

### Variable Assignments
```
[% foo = 'abc' %]
[% SET foo = 'def' %]
```

Note that `SET` is optional and both forms above are equivalent.

### Variable Output
```
[% foo %]
```

### Branching
```
[% IF foo == 'abc' %]
Foo is abc!

[% ELSIF subsys %]
Foo is not abc!
[% END %]
```

### Comment
```
[%# this will not appear in rendered files #%]
```

### Snippet Reuse
```
[% BLOCK snippet %]
I am a snippet.
[% END %]

[% INCLUDE snippet %]
Hello!
[% PROCESS snippet %]
```

This will be rendered as:
```
I am a snippet.
Hello!
I am a snippet.
```

**Note:** Passing variables to block is **not** supported. `INCLUDE` and `PROCESS` are equivalent.

### Built-in Variables
For convenience, the `mini-tt2.pl` tool always automatically inject the following variables
into the template:

Their value depends only on the `SUBSYS` passed when invoking `make`.

**Note:** Variable names in TT2 are case-sensitive.

| Variable        | Type     | Value when `SUBSYS == "http"` | Value when `SUBSYS == "stream"` |
| --------------- | -------- | ----------------------------- | ------------------------------- |
| `subsys`        | String   | `"http"`                      | `"stream"`                      |
| `SUBSYS`        | String   | `"HTTP"`                      | `"STREAM"`                      |
| `req_type`      | String   | `"ngx_http_request_t"`        | `"ngx_stream_lua_request_t"`    |
| `req_subsys`    | String   | `"http"`                      | `"stream_lua"`                  |
| `http_subsys`   | Boolean  | `1`                           | `0`                             |
| `stream_subsys` | Boolean  | `0`                           | `1`                             |

### Whitespace Control
Whitespace control using output modifiers like `[% foo -%]` is not necessary. The `mini-tt2.pl`
always suppresses whitespaces caused by template directives in the rendered files.

# Community

## English Mailing List

The [openresty-en](https://groups.google.com/group/openresty-en) mailing list is for English speakers.

## Chinese Mailing List

The [openresty](https://groups.google.com/group/openresty) mailing list is for Chinese speakers.

# Copyright and License

This repository is licensed under the BSD license.

Copyright (C) 2009-2017, by Xiaozhe Wang (chaoslawful) <chaoslawful@gmail.com>.

Copyright (C) 2009-2018, by Yichun "agentzh" Zhang (章亦春) <agentzh@gmail.com>, OpenResty Inc.

All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

* Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.

* Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
