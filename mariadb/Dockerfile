FROM centos:7
LABEL maintainer=jager<im@zhang.ge> description="MairaDB Base Image"

# COPY init_mariadb_repo.sh /tmp/init_mariadb_repo.sh
# RUN chmod +x  /tmp/init_mariadb_repo.sh && /tmp/init_mariadb_repo.sh
ARG VERSION=10.6
RUN VERSION=${VERSION}
RUN echo -e "# MariaDB ${VERSION} CentOS repository list - created $(date -u) \n\
    # http://downloads.mariadb.org/mariadb/repositories/ \n\
    name = MariaDB \n\
    baseurl = http://yum.mariadb.org/${VERSION}/centos7-amd64 \n\
    gpgkey=https://yum.mariadb.org/RPM-GPG-KEY-MariaDB \n\
    gpgcheck=1" >> /etc/yum.repos.d/mariadb.repo

RUN groupadd -r mysql \
    && useradd -r -g mysql mysql \
    && rpm --import http://yum.mariadb.org/RPM-GPG-KEY-MariaDB \
    && yum clean all \
    && yum makecache \
    && yum install -y which \
    && yum install -y epel-release \
    && yum install -y telnet socat pv \
       MariaDB-server MariaDB-client MariaDB-backup \
    && yum clean all \
    && rm -rf /var/cache/yum \
    && rm -rf /var/lib/mysql/* \
    && localedef -c -f UTF-8 -i zh_CN zh_CN.utf8 \
    && echo 'LC_CTYPE="en_US.UTF-8"' > /etc/sysconfig/i18n \
    && ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime

ENV TERM=linux \
    LANG=zh_CN.UTF-8 \
    LC_ALL=zh_CN.UTF-8 \
    base_dir=/data/mariadb-galera

COPY docker-entrypoint.sh /
ENTRYPOINT ["/docker-entrypoint.sh"]

CMD ["mysqld_safe"]

