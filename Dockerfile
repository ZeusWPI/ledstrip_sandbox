ARG DUB_CONFIG="rpi2-bookworm"
ARG DUB_ARCH="arm-linux-cortex-7a-gnueabihf"
ARG DUB_BUILD_TYPE="release"


FROM debian:bookworm AS base


FROM base AS extract-deb-libs

WORKDIR /work/debs
RUN dpkg --add-architecture armhf
RUN apt-get update
RUN chmod 777 .
RUN apt-get download libc6:armhf ldc:armhf libphobos2-ldc-shared100:armhf libssl3:armhf zlib1g:armhf libluajit-5.1-2:armhf
RUN for deb in *.deb; do dpkg-deb -R $deb $deb.extracted; done
RUN mkdir /work/libs
RUN find . -name "*\.a*" -exec cp "{}" /work/libs/ ";"
RUN find . -name "*\.so*" -exec cp "{}" /work/libs/ ";"
RUN find . -name "*\.o*" -exec cp "{}" /work/libs/ ";"
RUN rm -rf /work/debs


FROM base AS build-ws2811

RUN apt-get update && apt-get install -y \
    git cmake ninja-build \
    gcc-12-arm-linux-gnueabihf g++-12-arm-linux-gnueabihf

ENV CC=arm-linux-gnueabihf-gcc-12
ENV CXX=arm-linux-gnueabihf-g++-12

WORKDIR /work/rpi_ws281x
RUN git clone https://github.com/jgarff/rpi_ws281x.git .
RUN git checkout 1f47b59
RUN cmake -B build -S . -G Ninja -DBUILD_SHARED=OFF -DBUILD_TEST=OFF
RUN cmake --build build
RUN cp build/libws2811.a /work/
RUN rm -rf /work/rpi_ws281x


FROM base AS build


RUN apt-get update && apt-get install -y gcc-12-arm-linux-gnueabihf

# Needed for the openssl package
RUN apt-get update && apt-get install -y gcc dub ldc
ENV DC=ldc2

WORKDIR /work

ARG DUB_CONFIG
ARG DUB_ARCH
ARG DUB_BUILD_TYPE

COPY dub.sdl dub.selections.json .
RUN dub build --config="${DUB_CONFIG}" --arch="${DUB_ARCH}" --build="${DUB_BUILD_TYPE}"

COPY source/ source/
RUN dub build --config="${DUB_CONFIG}" --arch="${DUB_ARCH}" --build="${DUB_BUILD_TYPE}"
RUN bash -c "xargs ar -rcT dlibs.a $(dub describe --data=linker-files)"

RUN mkdir /work/libs
COPY --from=extract-deb-libs /work/libs/* /work/libs/
COPY --from=build-ws2811 /work/libws2811.a /work/libs/
RUN arm-linux-gnueabihf-gcc-12 libledstrip.a -o ledstrip -Wl,--gc-sections \
    dlibs.a libs/libws2811.a \
    libs/ldc_rt.dso.o libs/libdruntime-ldc-shared.so.100 libs/libphobos2-ldc-shared.so.100 \
    libs/libluajit-5.1.so.2 \
    libs/libcrypto.so.3 libs/libssl.so.3 libs/libz.so.1 \
    libs/libc.so.6 libs/libm.so.6


FROM scratch AS artifact
COPY --from=build /work/ledstrip /ledstrip
