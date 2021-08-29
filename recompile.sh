if [ "${ORCHESTRA_ROOT}x" = "x" ]; then
  echo "Error: ORCHESTRA_ROOT is not set"
  exit 1
fi

$ORCHESTRA_ROOT/bin/clang -S -emit-llvm utils.cpp

$ORCHESTRA_ROOT/bin/llvm-link \
  -S \
  $1 \
  utils.ll \
  $ORCHESTRA_ROOT/share/revng/support-x86_64-normal.ll \
  -o \
  $1.linked.ll

$ORCHESTRA_ROOT/bin/llc \
  -O0 \
  $1.linked.ll \
  -o \
  $1.linked.ll.o \
  -disable-machine-licm \
  -filetype=obj

$ORCHESTRA_ROOT/link-only/bin/c++ \
  ./$1.linked.ll.o \
  -lz \
  -lm \
  -lrt \
  -lpthread \
  -L \
  ./ \
  -o \
  ./dummy.translated \
  -fno-pie \
  -no-pie \
  -Wl,-z,max-page-size=4096 \
  -Wl,--section-start=.o_r_0x400000=0x400000 \
  -Wl,--section-start=.o_rx_0x401000=0x401000 \
  -Wl,--section-start=.o_r_0x402000=0x402000 \
  -Wl,--section-start=.o_rw_0x403db8=0x403d68 \
  -fuse-ld=bfd \
  -Wl,--section-start=.elfheaderhelper=0x3fffff \
  -Wl,-Ttext-segment=0x405000 \
  -Wl,--no-as-needed \
  -ldl \
  -lstdc++ \
  -lc \
  -Wl,--as-needed

cp ./dummy.translated ./dummy.translated.tmp

$ORCHESTRA_ROOT/bin/revng \
  merge-dynamic \
  ./dummy.translated.tmp \
  ./dummy \
  ./dummy.translated