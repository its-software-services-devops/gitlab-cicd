FROM amazon/aws-cli:2.10.3

RUN aws --version
#RUN git -v
RUN docker

COPY scripts/* /scripts/
RUN chmod -R 555 /scripts/*

COPY utils/* /utils/
RUN chmod -R 555 /utils/*

COPY data/* /data/
RUN chmod -R 444 /data/*

ENV PATH="/utils:/scripts:${PATH}"
ENV SYSTEM_STATE_FILE=states.txt

ENV CLOUD_TYPE=aws
