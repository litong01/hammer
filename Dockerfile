FROM alpine:3.17.1 as BUILDER

RUN apk add curl && mkdir -p /work/bin && cd /work && \
    ARCH=$(uname -m) && if [[ "${ARCH}" == "aarch64" ]]; then ARCH=arm64; fi && \
    if [[ "${ARCH}" == "x86_64" ]]; then ARCH="amd64"; fi && \
    echo "Download kubectl..." && \
    curl -Lso kubectl "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/${ARCH}/kubectl" && \
    chmod +x kubectl && mv kubectl /work/bin/kubectl && \
    echo "Download helm..." && \
    curl -Lso helm.tar.gz https://get.helm.sh/helm-v3.11.0-linux-${ARCH}.tar.gz && \
    echo "Expand helm..." && \
    tar -xf helm.tar.gz && mv linux-${ARCH}/helm /work/bin/helm

FROM email4tong/kind:v0.17.1 as KINDSOURCE

FROM alpine:3.17.1
LABEL maintainer="litong01"

ENV PYTHONUNBUFFERED=1
RUN apk add --update --no-cache python3 && ln -sf python3 /usr/bin/python
RUN python3 -m ensurepip
RUN pip3 install --no-cache --upgrade pip setuptools requests requests_toolbelt
RUN apk add --update bash docker-cli git make curl rsync \
    openssl diffutils jq yq perl

COPY --from=BUILDER /work/bin/* /home/bin/
COPY ./main.sh /home/bin
COPY --from=KINDSOURCE /usr/local/bin/kind /home/bin
RUN rm -rf /var/cache/apk/* && rm -rf /tmp/* && apk update

ENV PATH $PATH:/home/bin
ENV HOME=/home

WORKDIR /home
CMD /home/bin/main.sh