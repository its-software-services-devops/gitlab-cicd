FROM google/cloud-sdk:357.0.0

RUN curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3
RUN chmod 700 get_helm.sh
RUN ./get_helm.sh

RUN helm version
RUN gcloud version

RUN helm plugin install https://github.com/hayorov/helm-gcs.git

RUN curl -L -o jsonnet.tar.gz https://github.com/google/jsonnet/releases/download/v0.17.0/jsonnet-bin-v0.17.0-linux.tar.gz
RUN tar -xvf jsonnet.tar.gz; cp jsonnet jsonnetfmt /usr/bin/
RUN jsonnet --version

COPY scripts/* /scripts/
RUN chmod -R 555 /scripts/*

COPY utils/* /utils/
RUN chmod -R 555 /utils/*

COPY data/* /data/
RUN chmod -R 444 /data/*

ENV PATH="/utils:/scripts:${PATH}"
ENV GOOGLE_APPLICATION_CREDENTIALS=/gcloud/secret/key.json
ENV SYSTEM_STATE_FILE=states.txt
