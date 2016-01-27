#!/bin/bash -xue

function build() {
    local suffix=$1
    shift
    local host=$1
    shift
    local cflags=$1

    set +e
    ./configure --host=${host} CFLAGS=${cflags}
    RC=$?
    set -e

    if ! test x$RC = x0; then
        test -f config.log && cat config.log
        return $RC
    fi

    make V=1

    mv reedsolomon-gal-mul-stdio reedsolomon-gal-mul-stdio-$suffix

    make distclean
}

unset CC
cd cbits

HOST_ISA=`uname -p`

build $HOST_ISA '' ''
build arm arm-linux-gnueabihf ''
build arm-neon arm-linux-gnueabihf '-mfpu=neon'
build ppc64le powerpc64le-linux-gnu '-mno-altivec'
build ppc64le-altivec powerpc64le-linux-gnu '-maltivec'
build ppc64le-power8 powerpc64le-linux-gnu '-mcpu=power8'

stack runhaskell --resolver=$RESOLVER reedsolomon-gal-mul-stdio-quickcheck.hs -- \
    ./reedsolomon-gal-mul-stdio-$HOST_ISA \
    'qemu-arm-static -L /usr/arm-linux-gnueabihf ./reedsolomon-gal-mul-stdio-arm'
stack runhaskell --resolver=$RESOLVER reedsolomon-gal-mul-stdio-quickcheck.hs -- \
    ./reedsolomon-gal-mul-stdio-$HOST_ISA \
    'qemu-arm-static -L /usr/arm-linux-gnueabihf ./reedsolomon-gal-mul-stdio-arm-neon'

stack runhaskell --resolver=$RESOLVER reedsolomon-gal-mul-stdio-quickcheck.hs -- \
    ./reedsolomon-gal-mul-stdio-$HOST_ISA \
    'qemu-ppc64le-static -L /usr/powerpc64le-linux-gnu ./reedsolomon-gal-mul-stdio-ppc64le'
stack runhaskell --resolver=$RESOLVER reedsolomon-gal-mul-stdio-quickcheck.hs -- \
    ./reedsolomon-gal-mul-stdio-$HOST_ISA \
    'qemu-ppc64le-static -L /usr/powerpc64le-linux-gnu ./reedsolomon-gal-mul-stdio-ppc64le-altivec'
stack runhaskell --resolver=$RESOLVER reedsolomon-gal-mul-stdio-quickcheck.hs -- \
    ./reedsolomon-gal-mul-stdio-$HOST_ISA \
    'qemu-ppc64le-static -cpu POWER8 -L /usr/powerpc64le-linux-gnu ./reedsolomon-gal-mul-stdio-ppc64le-power8'