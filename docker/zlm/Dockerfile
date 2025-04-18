FROM zlm_dev AS build

FROM ubuntu:20.04

ARG MODEL=Release

EXPOSE 80/tcp
EXPOSE 1935/tcp
EXPOSE 554/tcp
EXPOSE 554/udp
EXPOSE 30000-30064/tcp
EXPOSE 30000-30064/udp

# ADD sources.list /etc/apt/sources.list

RUN sed -i 's/archive.ubuntu.com/mirrors.aliyun.com/g' /etc/apt/sources.list \
    && apt-get update \
    && DEBIAN_FRONTEND="noninteractive" \
        apt-get install -y --no-install-recommends \
        vim \
        wget \
        ca-certificates \
        tzdata \
        curl \
        libssl-dev \
        ffmpeg \
        gcc \
        g++ \
        gdb \
    && apt-get autoremove -y \
    && apt-get clean -y \
    && rm -rf /var/lib/apt/lists/*

ENV TZ=Asia/Shanghai
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime \
        && echo $TZ > /etc/timezone && \
        mkdir -p /opt/media/bin/www

WORKDIR /opt/media/bin/
COPY --from=build /home/media/ZLMediaKit/release/linux/${MODEL}/MediaServer /home/media/ZLMediaKit/default.pem /opt/media/bin/
COPY --from=build /home/media/ZLMediaKit/release/linux/${MODEL}/config.ini /opt/media/conf/
COPY --from=build /home/media/ZLMediaKit/www/ /opt/media/bin/www/

ENV PATH=/opt/media/bin:$PATH

CMD ["./MediaServer","-s", "default.pem", "-c", "../conf/config.ini", "-l","0"]
