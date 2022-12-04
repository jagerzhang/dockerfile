ARG VERSION=2.0
FROM kong:${VERSION}
LABEL maintainer="Jagerzhang BaseOn Official image of Kong, feedback: https://zhang.ge/"
WORKDIR /usr/local/kong
COPY nginx.conf.template .
COPY docker-entrypoint.sh /
