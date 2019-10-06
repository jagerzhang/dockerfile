#!/bin/sh
# first arg is `-f` or `--some-option`
if [ "${1#-}" != "$1" ]; then
    set -- haproxy "$@"
fi

if [ "$1" = 'haproxy' ]; then
    if [ -z $VIP ];then
        echo echo "[$(date '+%F %H:%M:%S')] ENV \${VIP} is not SET, Plz check!"
        exit 1
    fi
    mkdir -p /usr/local/haproxy/logs/
    bash /opt/update_cfg.sh
    ln -sf /usr/local/haproxy/etc/${VIP}.cfg /etc/haproxy.cfg
    haproxy -W -c -f /etc/haproxy.cfg || (
        echo "[$(date '+%F %H:%M:%S')] Haproxy Configuration file check failed, Plz check!"
        exit 1
    )
    shift # "haproxy"
    # if the user wants "haproxy", let's add a couple useful flags
    #   -W  -- "master-worker mode" (similar to the old "haproxy-systemd-wrapper"; allows for reload via "SIGUSR2")
    #   -db -- disables background mode
    set -- haproxy -W -db "$@"
fi

exec "$@"
