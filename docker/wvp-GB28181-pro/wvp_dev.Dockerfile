FROM ubuntu:20.04 AS base

EXPOSE 18080/tcp
EXPOSE 5060/tcp
EXPOSE 5060/udp
EXPOSE 18081/tcp
# EXPOSE 80/tcp
# EXPOSE 1935/tcp
# EXPOSE 554/tcp
# EXPOSE 554/udp
# EXPOSE 30000-30064/tcp
# EXPOSE 30000-30064/udp


WORKDIR /home/media/wvp

RUN sed -i 's/archive.ubuntu.com/mirrors.aliyun.com/g' /etc/apt/sources.list \
    && apt update \
    && DEBIAN_FRONTEND="noninteractive" \
    apt-get install -y --no-install-recommends \
    openjdk-11-jre git maven nodejs npm build-essential \
    cmake ca-certificates openssl ffmpeg

COPY ./docker/wvp-GB28181-pro/maven/settings.xml /usr/share/maven/conf/settings.xml

COPY ./src/wvp-pro-assist /home/media/wvp-assist
RUN rm -f /home/media/wvp-assist/.git
COPY .git/modules/src/wvp-pro-assist /home/media/wvp-assist/.git

RUN mkdir -p /opt/wvp/config /opt/wvp/heapdump \
    /opt/wvp/config /opt/assist/config \
    /opt/assist/heapdump /opt/media/www/record 



WORKDIR /home/media/wvp-assist
RUN mvn clean package -Dmaven.test.skip=true \
    && cp /home/media/wvp-assist/target/*.jar /opt/assist/ \
    && cp /home/media/wvp-assist/src/main/resources/application-dev.yml /opt/assist/config/application.yml


COPY ./src/wvp-GB28181-pro /home/media/wvp
RUN rm -f /home/media/wvp/.git
COPY .git/modules/src/wvp-GB28181-pro /home/media/wvp/.git

WORKDIR /home/media/wvp/web_src
RUN npm install && npm run build

WORKDIR /home/media/wvp
RUN mvn clean package -Dmaven.test.skip=true \
    && cp /home/media/wvp/target/*.jar /opt/wvp/
    
COPY ./docker/wvp-GB28181-pro/application-docker.yml /opt/wvp/config/application.yml

# RUN cp -r /home/media/ZLMediaKit/release/linux/Debug/* /opt/media \
#     && rm -f /opt/media/config.ini

RUN cd /opt/wvp && \
    echo '#!/bin/bash' > run.sh && \
    echo 'echo ${WVP_IP}' >> run.sh && \
    echo 'echo ${WVP_CONFIG}' >> run.sh && \
    echo 'cd /opt/assist' >> run.sh && \
    echo 'nohup java ${ASSIST_JVM_CONFIG} -XX:+HeapDumpOnOutOfMemoryError -XX:HeapDumpPath=/opt/assist/heapdump/ -jar *.jar --spring.config.location=/opt/assist/config/application.yml --userSettings.record=/opt/media/www/record/  --media.record-assist-port=18081 ${ASSIST_CONFIG} &' >> run.sh && \
    # echo 'nohup /opt/media/MediaServer -d -m 3 &' >> run.sh && \
    echo 'cd /opt/wvp' >> run.sh && \
    echo 'java ${WVP_JVM_CONFIG} -XX:+HeapDumpOnOutOfMemoryError -XX:HeapDumpPath=/opt/wvp/heapdump/ -jar *.jar --spring.config.location=/opt/wvp/config/application.yml --media.record-assist-port=18081 ${WVP_CONFIG}' >> run.sh && \
    chmod +x run.sh

WORKDIR /opt/wvp

CMD ["/bin/bash", "-c"]
