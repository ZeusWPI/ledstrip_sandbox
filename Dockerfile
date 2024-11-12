ARG DUB_CONFIG="rpi2-bookworm"
ARG DUB_ARCH="arm-linux-cortex-7a-gnueabihf"
ARG DUB_BUILD_TYPE="debug"

FROM debian:bookworm AS base
FROM --platform=linux/arm/v7 debian:bookworm AS base-target
FROM node:lts AS base-node


# Fetch static and dynamic libs from cross target
FROM base AS extract-deb-libs

WORKDIR /work/debs
RUN dpkg --add-architecture armhf
RUN apt-get update
RUN chmod 777 .
RUN apt-get download \
    libc6:armhf \
    ldc:armhf libphobos2-ldc-shared-dev:armhf \
    libssl3:armhf zlib1g:armhf \
    libluajit-5.1-2:armhf \
    libpython3.11:armhf libexpat1:armhf
RUN for deb in *.deb; do dpkg-deb -R $deb $deb.extracted; done
RUN mkdir /work/libs
RUN find . -name "*\.a*" -exec cp "{}" /work/libs/ ";"
RUN find . -name "*\.so*" -exec cp "{}" /work/libs/ ";"
RUN find . -name "*\.o*" -exec cp "{}" /work/libs/ ";"
RUN rm -rf /work/debs

# Cross compile libws2811
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


# Cross compile the ledstrip D backend
FROM base AS build-backend

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
    libs/libpython3.11.so.1 libs/libexpat.so.1 \
    libs/libluajit-5.1.so.2 \
    libs/libcrypto.so.3 libs/libssl.so.3 libs/libz.so.1 \
    libs/ldc_rt.dso.o libs/libdruntime-ldc-debug-shared.so.100 libs/libphobos2-ldc-debug-shared.so.100 \
    libs/libc.so.6 libs/libm.so.6


# Build the ledstrip frontend
FROM base-node AS build-frontend

RUN corepack enable pnpm

WORKDIR /work

COPY frontend/package.json frontend/pnpm-lock.yaml .
RUN pnpm install

COPY frontend/src/ src/
COPY frontend/index.html frontend/tsconfig.json frontend/vite.config.js .
RUN pnpm run build


# Build the lua language server
FROM base-target AS build-luals

RUN apt-get update && apt-get install -y \
    build-essential git wget cmake ninja-build

WORKDIR /work

RUN git clone https://github.com/LuaLS/lua-language-server.git . \
    --branch "3.11.1" \
    --recurse-submodules
RUN cd 3rd/luamake && compile/build.sh
RUN 3rd/luamake/luamake -notest

RUN mkdir out out/locale out/meta
RUN cp -r bin script main.lua debugger.lua out/
RUN cp -r locale/en-us out/locale/
RUN cp -r meta/spell out/meta
COPY luals/meta out/meta/template
COPY luals/config.lua out/


# Build the websocket wrapper for the lua language server
FROM base-node AS build-luals-ws-wrapper

RUN corepack enable pnpm

WORKDIR /work

COPY luals/ws-wrapper/package.json luals/ws-wrapper/pnpm-lock.yaml .
RUN pnpm install

COPY luals/ws-wrapper/src src
RUN pnpm run build


# Copy build results into a single output artifact
FROM scratch AS artifact

COPY --from=build-backend          /work/ledstrip         /ledstrip
COPY --from=build-frontend         /work/dist             /public
COPY --from=build-luals            /work/out              /luals
COPY --from=build-luals-ws-wrapper /work/dist/main.js     /luals/ws-wrapper.js

