FROM haproxy:1.9

RUN sed -i "s@http://.*\.debian\.org@http://mirrors.aliyun.com@g" /etc/apt/sources.list \
    && rm -Rf /var/lib/apt/lists/* \
    && apt-get update \
    && apt-get install -y curl vim procps net-tools \
    && apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false

HEALTHCHECK --interval=5s CMD /opt/mon.sh
COPY mon.sh /opt/
COPY update_cfg.sh /opt/
COPY docker-entrypoint.sh /
COPY haproxy_exporter /opt/
COPY Dockerfile /

CMD ["haproxy","-f","/etc/haproxy.cfg"]
