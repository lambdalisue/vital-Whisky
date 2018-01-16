ARG TAG="latest"
FROM lambdalisue/vim-themis:${TAG}
MAINTAINER lambdalisue <lambdalisue@hashnote.net>

RUN apk add --no-cache --virtual build-deps git \
 && apk add --no-cache python3 \
 && apk del build-deps
