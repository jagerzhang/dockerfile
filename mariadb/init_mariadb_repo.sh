ucpu=$(uname -m | tr '[A-Z]' '[a-z]')
case $ucpu in
    *amd*64* | *x86-64* | *x86_64*)
        case $(getconf LONG_BIT) in
        64)
            mycpu="amd64"
            ;;
        32)
            mycpu="i386"
            ;;
        esac
        ;;
    *aarch64*)
        mycpu="aarch64"
        ;;
    *)
        echo "不支持: $ucpu"
        exit 1
esac

cat > /etc/yum.repos.d/mariadb.repo << EOF
# MariaDB ${VERSION} CentOS repository list - created $(date -u)
# http://downloads.mariadb.org/mariadb/repositories/
[mariadb]
name = MariaDB
baseurl = http://yum.mariadb.org/${VERSION}/centos7-${mycpu}
gpgkey=https://yum.mariadb.org/RPM-GPG-KEY-MariaDB
gpgcheck=1
EOF