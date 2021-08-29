# dlsym_hook.nim
Impressed by blog post ["Instrumenting binaries using revng and LLVM"](https://layle.me/posts/instrumentation-with-revng), so I want play with [Nim](https://nim-lang.org/)

Here is [original](https://github.com/ioncodes/dlsym_hook) example.

**Thanks to @ioncodes for a great article!**

## Getting started
Make sure you have [orchestra](https://github.com/revng/orchestra) and [revng](https://github.com/revng/revng) installed.

In order to use scripts provided, ORCHESTRA_ROOT enviroment parameters must be set and point to your orchestra root folder.
```sh
# Compile dummy example
> sh compile.sh

# Lifting dummy to LLVM IR
> sh lift.sh

# Process lifted IR w/ Nim
> nimble install https://github.com/ba0f3/llvm.nim
> nim c -r dlsym_hook.nim dummy.translated.ll dummy.translated.processed.ll
...................
Loaded IR: dummy.translated.ll
Verification: 0
Ouput: dummy.translated.processed.ll

# Recompile processed IR
> sh recompile.sh dummy.translated.processed.ll

# Here is the output
> ./dummy.translated
dlsym => 0x1
dlsym => 0x41c10c88
dlsym(???, ��A);
dlsym => 0x41c10c88
dlsym(???, ��A);
dlsym => 0xffff
dlsym => 0x404061
dlsym(???, );
-- test dlsym --
dlsym => 0x4
dlsym => 0x1420dc0
dlsym(???, puts);
dlsym => 0x4
test
```

That's all!