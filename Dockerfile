FROM alpine:latest
LABEL maintainer="Abdullah Morgan paapaabdullahm@gmail.com"

RUN apk -U add openssl

ENV VERSION 0.7.4
ENV DOWNLOAD_URL https://github.com/jwilder/docker-gen/releases/download/$VERSION/docker-gen-alpine-linux-amd64-$VERSION.tar.gz
ENV DOCKER_HOST unix:///tmp/docker.sock

RUN wget -qO- $DOWNLOAD_URL | tar xvz -C /usr/bin

ENTRYPOINT ["/usr/bin/docker-gen"]
