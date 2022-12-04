FROM haproxy:2.1.0

RUN apt-get update \
    && apt-get install -y curl vim procps net-tools \
    && apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false

COPY update_cfg.sh /opt/
COPY docker-entrypoint.sh /
RUN chmod +x /docker-entrypoint.sh
CMD ["haproxy","-f","/etc/haproxy.cfg"]
