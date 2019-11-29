#!/bin/bash
ip2dec() {
    local a b c d ip=$@
    IFS=. read -r a b c d <<< "$ip"
    printf '%d\n' "$((a * 256 ** 3 + b * 256 ** 2 + c * 256 + d))"
}

if ! ps aux | grep -v grep | grep -wq haproxy_exporter;then
    if [[ -z $VIP ]];then
        exit 1
    fi
    port_int=$(ip2dec $VIP)
    port="2${port_int:$((-4))}"
    nohup /opt/haproxy_exporter --haproxy.scrape-uri=unix:/run/haproxy.sock --web.listen-address="0.0.0.0:$port"  >/dev/null 2>&1 &
    exit 1
fi
