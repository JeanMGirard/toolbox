FROM golang:1.19.3-alpine

#USER toolbox

RUN apk update \
    && apk upgrade --no-cache \
    && apk add --no-cache bash \
    && mkdir -p /tmp/setup

WORKDIR /tmp/setup

ADD . .

RUN chmod +x ./scripts/*.sh \
    && bash ./scripts/install.sh

VOLUME  /app
WORKDIR /app

RUN rm -rf /tmp/setup


ENTRYPOINT ["/bin/sh", "-c"]
CMD ["bash"]
