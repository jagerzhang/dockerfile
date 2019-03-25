FROM centos:7.5.1804
MAINTAINER jagerzhang<jagerzhang@tencent.com>

COPY mariadb.repo /etc/yum.repos.d/mariadb.repo

RUN groupadd -r mysql \
    && useradd -r -g mysql mysql \
    && rpm --import https://mirrors.ustc.edu.cn/mariadb/yum/RPM-GPG-KEY-MariaDB \
    && yum clean all \
    && yum makecache \
    && yum install -y epel-release \
    && yum install -y socat pv \
       MariaDB-server-10.3.12-1.el7.centos.x86_64 \
       MariaDB-client-10.3.12-1.el7.centos.x86_64 \
       MariaDB-backup-10.3.12-1.el7.centos.x86_64 \
    && yum clean all \
    && rm -rf /var/cache/yum \
    && rm -rf /var/lib/mysql/* \
    && localedef -c -f UTF-8 -i zh_CN zh_CN.utf8 \
    && echo 'LC_CTYPE="en_US.UTF-8"' > /etc/sysconfig/i18n \
    && ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime

ENV TERM=xterm \
    LANG=zh_CN.UTF-8 \
    LC_ALL=zh_CN.UTF-8 \
    base_dir=/data/mariadb-galera

COPY docker-entrypoint.sh /
ENTRYPOINT ["/docker-entrypoint.sh"]

CMD ["mysqld_safe"]
