FROM alpine:3.14
MAINTAINER Exonorid <exonorid@gmail.com>

RUN apk update
# Test dependencies
RUN apk add make python3

# Get Zig 0.9.0 (or at least as close as possible)
RUN apk add xz wget
RUN mkdir -p /deps
WORKDIR /deps
RUN curl https://ziglang.org/builds/zig-linux-x86_64-0.9.0-dev.1371+b0f80ef0d.tar.xz && \
    tar xf zig-linux-x86_64-0.9.0-dev.1371+b0f80ef0d.tar.xz -C /deps/zig && \
    ln -s /deps/zig/zig /usr/bin/zig

RUN mkdir -p /mal
WORKDIR /mal
ENV HOME /mal
