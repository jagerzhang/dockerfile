FROM zctmdc/mariadb:10.6
LABEL maintainer=jager<im@zhang.ge> description="MairaDB Galera Cluster Image" articles=https://zhang.ge/5150.html

ENV my_port=3307 \
    base_dir=/data/mariadb-galera

RUN sed -i '/wsrep_sst_common$/a\
    rlimit=$(parse_cnf sst rlimit ""|grep -o "[0-9]*"|head -1)\n\
    if [[ ! -z $rlimit ]];\n\
    then\n\
        RSYNC_TRANSFER_LIMIT="--bwlimit $rlimit"\n\
    else\n\
        RSYNC_TRANSFER_LIMIT=""\n\
    fi' /usr/bin/wsrep_sst_rsync \
    && sed -i '/find . -maxdepth/i\
    if [[ ! -z $RSYNC_TRANSFER_LIMIT ]];\n\
    then\n\
        count=1\n\
    fi' /usr/bin/wsrep_sst_rsync \
    && sed -i 's/--quiet/--quiet $RSYNC_TRANSFER_LIMIT/g' /usr/bin/wsrep_sst_rsync

COPY auto-join-cluster.sh /
COPY server.cnf.sample /etc/my.cnf.d/
COPY wsrep.cnf.sample /etc/my.cnf.d/
COPY docker-entrypoint.sh /
COPY galera-entrypoint.sh /
ENTRYPOINT ["/galera-entrypoint.sh"]

CMD ["mysqld_safe"]
