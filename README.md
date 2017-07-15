# Name
meta-lua-nginx-module - templates and toolchains for generating
http-lua-nginx-module and stream-lua-nginx-module.

This module is experimental and should not be used in production yet.

# Usage
```shell
$ make SUBSYSTEM=http
```

or
```shell
$ make SUBSYSTEM=stream
```

The generated files will be located under `build/src`.
