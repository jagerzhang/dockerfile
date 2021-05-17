#!/bin/bash
if [[ ! -f "$lock_dir/initdb.lock" ]]; then
    echo '>> initializing database'
    mysql_install_db --user=mysql --datadir="$my_datadir" --rpm "${@:2}"
    echo '>> database initialized'
    
    # mariadb galera集群node1启动或普通maridb模式或单点galera模式将进行下面的初始化，其他将跳过，因为galera会同步数据，无需重复初始化
    if [[ $first_start -eq 1 ]] || [[ ! -f $conf_dir/wsrep.cnf ]] || [[ $cluster_mode -ne 1 ]];then
        mysqld --skip-networking --user=mysql --socket="/tmp/mysql.sock" &
        pid="$!"
    
        mysql=( mysql --protocol=socket -uroot -hlocalhost -f --socket="/tmp/mysql.sock" )
        if [[ -f /etc/my.cnf.d/wsrep.cnf ]];then
            echo ">> Found the galera configuration, waiting for mysql really start"
            while true;do
                if echo 'select 1' | "${mysql[@]}" &> /dev/null; then
                    break
                fi
                if echo 'select 1' | "${mysql[@]}" -p${mysql_root_password} &> /dev/null; then
                    break
                fi 
                echo '>> mysql init process in progress...'
                sleep 1
            done
        else
            for i in {60..0}; do
                if echo 'select 1' | "${mysql[@]}" &> /dev/null; then
                    break
                fi
                echo '>> mysql init process in progress...'
                sleep 1
            done
            if [ "$i" = 0 ]; then
                echo >&2 '>> mysql init process failed.'
                exit 1
            fi
        fi
    
        if [[ ! -z "$mysql_random_root_password" ]] &&  [[ -z $mysql_root_password ]]; then
            export mysql_root_password="$(echo $RANDOM | sha256sum | base64 | head -c 16)"
            echo ">> generated root password: $mysql_root_password"
        fi
    
        rootcreate=
        # default root to listen for connections from anywhere
        if [[ ! -z "$mysql_root_password" ]] && [[ ! -z "$mysql_root_host" ]]; then
            # no, we don't care if read finds a terminating character in this heredoc
            # https://unix.stackexchange.com/questions/265149/why-is-set-o-errexit-breaking-this-read-heredoc-expression/265151#265151
            read -r -d '' rootcreate <<-EOSQL || true
                create user 'root'@'${mysql_root_host}' identified by '${mysql_root_password}' ;
                grant all on *.* to 'root'@'${mysql_root_host}' with grant option ;
EOSQL
        fi
        # set @@session.sql_log_bin=0;
        # set password for 'root'@'localhost'=password('${mysql_root_password}') ;
        "${mysql[@]}" <<-EOSQL
            delete from mysql.user where ( host not in ('127.0.0.1','localhost','::1') and user = 'root' ) or user = '';
            grant all on *.* to 'root'@'127.0.0.1'  identified by '${mysql_root_password}' with grant option;
            grant all on *.* to 'root'@'localhost'  identified by '${mysql_root_password}' with grant option;
            grant all on *.* to 'root'@'::1'  identified by '${mysql_root_password}' with grant option;
            grant all on *.* to 'sst'@'%'  identified by '${mysql_sst_password}';
            ${rootcreate}
            drop database if exists test ;
            flush privileges ;
EOSQL
    
        if [ ! -z "$mysql_root_password" ]; then
            mysql+=( -p"${mysql_root_password}" )
        else
            echo ">> WARNNING: password for root is Empty, not recommended!" 
        fi
        if [ ! -z "$mysql_database" ]; then
            echo "create database if not exists $mysql_database ;" | "${mysql[@]}"
            mysql+=( "$mysql_database" )
        fi
        
        # create custom user 
        if [[ ! -z "$mysql_user" ]] && [[ ! -z "$mysql_user_password" ]]; then
            mysql_user_host=${mysql_user_host:-'%'}
            mysql_user_database=${mysql_user_database:-'*'}
            echo "create user '$mysql_user'@'$mysql_user_host' identified by '$mysql_user_password' ;" | "${mysql[@]}"
            if [[ $mysql_user_grant -eq 1 ]];then
                echo "grant all on $mysql_user_database.* to '$mysql_user'@'$mysql_user_host' with grant option;" | "${mysql[@]}"
            else
                echo "grant all on $mysql_user_database.* to '$mysql_user'@'$mysql_user_host' ;" | "${mysql[@]}"
            fi
        fi
    
        echo
        for f in $base_dir/initdb.d/*; do
            case "$f" in
                *.sh)     echo "$0: running $f"; . "$f" ;;
                *.sql)    echo "$0: running $f"; "${mysql[@]}" < "$f"; echo ;;
                *.sql.gz) echo "$0: running $f"; gunzip -c "$f" | "${mysql[@]}"; echo ;;
                *)        echo "$0: ignoring $f" ;;
            esac
            echo
        done
    
        if ! kill -s term "$pid" || ! wait "$pid"; then
            echo >&2 '>> mysql init process failed.'
            exit 1
        fi
    
        echo
        echo '>> mysql init process done. ready for start up.'
        echo
    fi
cat > $lock_dir/initdb.lock <<EOF
MariaDB Has been Initialized, Delete this file will force initialize.
EOF
else
    echo ">> MariaDB Has been Initialized, Skiped (Delete the file $lock_dir/initdb.lock to force initialize)."
fi

exec "$@"
