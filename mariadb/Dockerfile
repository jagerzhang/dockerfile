FROM centos:7
LABEL maintainer=jager<im@zhang.ge> description="MairaDB Base Image"

ARG VERSION=10.6
RUN VERSION=${VERSION}

COPY init_mariadb_repo.sh /tmp/init_mariadb_repo.sh
RUN chmod +x  /tmp/init_mariadb_repo.sh 
RUN /tmp/init_mariadb_repo.sh

RUN cat /etc/yum.repos.d/mariadb.repo

RUN groupadd -r mysql
RUN useradd -r -g mysql mysql
RUN rpm --import http://yum.mariadb.org/RPM-GPG-KEY-MariaDB
RUN yum makecache
RUN yum install -y epel-release
RUN yum install -y which
RUN yum install -y telnet socat pv MariaDB-server MariaDB-client MariaDB-backup
RUN yum clean all
RUN rm -rf /var/cache/yum && rm -rf /var/lib/mysql/*
RUN localedef -c -f UTF-8 -i zh_CN zh_CN.utf8
RUN echo 'LC_CTYPE="en_US.UTF-8"' > /etc/sysconfig/i18n
RUN ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime

ENV TERM=linux \
    LANG=zh_CN.UTF-8 \
    LC_ALL=zh_CN.UTF-8 \
    base_dir=/data/mariadb-galera

COPY docker-entrypoint.sh /
ENTRYPOINT ["/docker-entrypoint.sh"]

CMD ["mysqld_safe"]

