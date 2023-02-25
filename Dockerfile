FROM ubuntu:22.04
#FROM amazon/aws-cli:2.10.3

RUN apt-get -y install awscli
RUN aws --version

RUN apt-get -y update
RUN apt-get -y install git

RUN apt-get update && \
    apt-get -qy full-upgrade && \
    apt-get install -qy curl && \
    apt-get install -qy curl && \
    curl -sSL https://get.docker.com/ | sh


RUN git --version
RUN docker --version

COPY scripts/* /scripts/
RUN chmod -R 555 /scripts/*

COPY utils/* /utils/
RUN chmod -R 555 /utils/*

COPY data/* /data/
RUN chmod -R 444 /data/*

ENV PATH="/utils:/scripts:${PATH}"
ENV SYSTEM_STATE_FILE=states.txt

ENV CLOUD_TYPE=aws
