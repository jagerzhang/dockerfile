FROM jagerzhang/mariadb:10.3.12
MAINTAINER jager<im@zhang.ge>

ENV my_port=3307 \
    base_dir=/data/mariadb-galera

RUN sed -i '/^#!\/bin\/sh/a\
    if [[ ! -z $rsync_transfer_limit ]];\
    then\n\
        RSYNC_TRANSFER_LIMIT="--bwlimit $rsync_transfer_limit"\n\
    else\n\
        RSYNC_TRANSFER_LIMIT=""\n\
    fi\n' /usr/bin/wsrep_sst_rsync \
    && sed -i 's/--quiet/--quiet $RSYNC_TRANSFER_LIMIT/g' /usr/bin/wsrep_sst_rsync

COPY auto-join-cluster.sh /
COPY server.cnf.sample /etc/my.cnf.d/
COPY wsrep.cnf.sample /etc/my.cnf.d/
COPY docker-entrypoint.sh /
COPY galera-entrypoint.sh /
ENTRYPOINT ["/galera-entrypoint.sh"]

CMD ["mysqld_safe"]
