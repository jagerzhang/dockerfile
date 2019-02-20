FROM jagerzhang/mariadb:10.3.12
MAINTAINER jager<im@zhang.ge>

ENV my_port=3307 \
    base_dir=/data/mariadb-galera

COPY auto-join-cluster.sh /
COPY server.cnf.sample /etc/my.cnf.d/
COPY wsrep.cnf.sample /etc/my.cnf.d/
COPY docker-entrypoint.sh /
COPY galera-entrypoint.sh /
ENTRYPOINT ["/galera-entrypoint.sh"]

CMD ["mysqld_safe"]
