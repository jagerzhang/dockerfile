FROM jagerzhang/mariadb:10.3.12
MAINTAINER jagerzhang<im@zhang.ge>

ENV my_port=3307 \
    base_dir=/data/mariadb-galera

RUN sed -i '/^#!\/bin\/sh/a\
    \\# Support to limit transfer speed in rsync mode\n\ 
    if [[ ! -z $rsync_transfer_limit ]];\
    then\n\
        RSYNC_TRANSFER_LIMIT="--bwlimit $rsync_transfer_limit"\n\
    else\n\
        RSYNC_TRANSFER_LIMIT=""\n\
    fi\n' /usr/bin/wsrep_sst_rsync \
    \\# Set the count of transfer to 1 when rsync_transfer_limit is defined\n\ 
    && sed -i '/find . -maxdepth/i\
    if [[ ! -z $rsync_transfer_limit ]];\
    then\n\
        count=1\n\
    fi\n' /usr/bin/wsrep_sst_rsync \
    && sed -i 's/--quiet/--quiet $RSYNC_TRANSFER_LIMIT/g' /usr/bin/wsrep_sst_rsync

COPY etc/auto-join-cluster.sh /
COPY etc/server.cnf.sample /etc/my.cnf.d/
COPY etc/wsrep.cnf.sample /etc/my.cnf.d/
COPY etc/docker-entrypoint.sh /
COPY etc/galera-entrypoint.sh /
ENTRYPOINT ["/galera-entrypoint.sh"]

CMD ["mysqld_safe"]
