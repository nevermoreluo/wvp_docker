FROM ubuntu:20.04 AS zlm_dev

ARG MODEL

EXPOSE 18080/tcp
EXPOSE 5060/tcp
EXPOSE 5060/udp
EXPOSE 6379/tcp
EXPOSE 18081/tcp
EXPOSE 80/tcp
EXPOSE 1935/tcp
EXPOSE 554/tcp
EXPOSE 554/udp
EXPOSE 30000-30064/tcp
EXPOSE 30000-30064/udp

RUN sed -i 's/archive.ubuntu.com/mirrors.aliyun.com/g' /etc/apt/sources.list \
    && apt update \
    && DEBIAN_FRONTEND="noninteractive" \
    apt install -y \
        --no-install-recommends \
        build-essential \
        cmake \
        git \
        curl \
        vim \
        wget \
        ca-certificates \
        tzdata \
        libssl-dev \
        gcc \
        g++ \
        gdb

RUN mkdir -p /home/media

COPY ./src/ZLMediaKit /home/media/ZLMediaKit
WORKDIR /home/media/ZLMediaKit

# 3rdpart init
WORKDIR /home/media/ZLMediaKit/3rdpart
RUN wget https://github.com/cisco/libsrtp/archive/v2.3.0.tar.gz -O libsrtp-2.3.0.tar.gz && \
    tar xfv libsrtp-2.3.0.tar.gz && \
    mv libsrtp-2.3.0 libsrtp && \
    cd libsrtp && ./configure --enable-openssl && make -j $(nproc) && make install
#RUN git submodule update --init --recursive && \

RUN mkdir -p build release/linux/${MODEL}/

WORKDIR /home/media/ZLMediaKit/build
RUN cmake -DCMAKE_BUILD_TYPE=${MODEL} -DENABLE_WEBRTC=true -DENABLE_FFMPEG=true -DENABLE_TESTS=false -DENABLE_API=false .. && \
    make -j $(nproc)

# runner dependencies
RUN apt install -y ffmpeg 

ENV TZ=Asia/Shanghai
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime \
        && echo $TZ > /etc/timezone && \
        mkdir -p /home/media/bin/www


CMD ["/bin/bash", "-c"]

