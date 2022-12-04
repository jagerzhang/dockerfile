#!/bin/sh
set -e

export KONG_NGINX_DAEMON=off
export nginx_cnf=${nginx_cnf:-nginx-custom.conf}

auto_init()
{
    nginx_cnf=$1
    test -f $nginx_cnf || touch $nginx_cnf
    env|while read VAR;do
        if [ "$VAR" != "${VAR#NGINX_}" ];then
            conf_name=$(echo "${VAR#NGINX_}" | sed -r 's/(.*)=.*/\1/g' | tr '[:upper:]' '[:lower:]')
            conf_value=${VAR#*=}
        else
            continue
        fi

        if grep -E -q '(^|^#)'"$conf_name(\s+)" $nginx_cnf; then
            echo "Modify $conf_name $conf_value; to $nginx_cnf"
            sed -r -i 's@(^|^#)('"$conf_name"')(\s+)(.*);@\2 '"${conf_value};"'@g' $nginx_cnf #note that no config values may contain an '@' char
        else
            echo "Add $conf_name $conf_value; to $nginx_cnf"
            echo "$conf_name ${conf_value};" >> $nginx_cnf
        fi
    done
}

if [[ "$1" == "kong" ]]; then
  PREFIX=${KONG_PREFIX:=/usr/local/kong}

  if [[ "$2" == "docker-start" ]]; then
    auto_init $PREFIX/$nginx_cnf
    kong prepare -p "$PREFIX" --nginx-conf $PREFIX/nginx.conf.template

    ln -sf /dev/stdout $PREFIX/logs/access.log
    ln -sf /dev/stdout $PREFIX/logs/admin_access.log
    ln -sf /dev/stderr $PREFIX/logs/error.log

    exec /usr/local/openresty/nginx/sbin/nginx \
      -p "$PREFIX" \
      -c nginx.conf
  fi
fi

exec "$@"
