#!/bin/bash
# 安装Nginx
yum install -y nginx

# 启动Nginx
/sbin/nginx

# 创建一个极简haproxy配置文件
cat > /usr/share/nginx/html/127.0.0.1 <<EOF
global
    nbproc 1
    pidfile /usr/local/haproxy/logs/127.0.0.1.pid

defaults
   timeout connect  300s
   timeout client   300s
   timeout server   300s

listen admin_stat
    bind 0.0.0.0:8080
    mode http
    stats refresh 60s
    stats uri /haproxy
    stats auth admin:123456
    stats admin if TRUE
################################################## status end ###############################################
EOF

test -f start.py && \
    python start.py
