FROM ubuntu:22.04

RUN apt-get -y update

RUN apt-get -y install git less groff curl unzip
RUN git --version

RUN curl https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip -o awscliv2.zip \
  && unzip awscliv2.zip \
  && ./aws/install \
  && rm -rf aws awscliv2.zip
RUN aws --version

RUN curl -sSL https://get.docker.com/ | sh
RUN docker --version

#### Custom script here ####
COPY scripts/* /scripts/
RUN chmod -R 555 /scripts/*

COPY utils/* /utils/
RUN chmod -R 555 /utils/*

COPY data/* /data/
RUN chmod -R 444 /data/*

ENV PATH="/utils:/scripts:${PATH}"
ENV SYSTEM_STATE_FILE=states.txt

ENV CLOUD_TYPE=aws
