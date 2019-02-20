#!/bin/bash
my_datadir=${my_datadir:-$base_dir}
if [[ ! -f "${my_datadir}/initdb.lock" ]]; then
    if [ -z "$MYSQL_ROOT_PASSWORD" -a -z "$MYSQL_ALLOW_EMPTY_PASSWORD" -a -z "$MYSQL_RANDOM_ROOT_PASSWORD" ]; then
        echo >&2 'error: database is uninitialized and password option is not specified '
        echo >&2 '  You need to specify one of MYSQL_ROOT_PASSWORD, MYSQL_ALLOW_EMPTY_PASSWORD and MYSQL_RANDOM_ROOT_PASSWORD'
        exit 1
    fi
    echo 'Initializing database'
    # "Other options are passed to mysqld." (so we pass all "mysqld" arguments directly here)
    mysql_install_db --user=mysql --datadir="$my_datadir" --rpm "${@:2}"
    echo 'Database initialized'
    
    mysqld --skip-networking --user=mysql --socket="/tmp/mysql.sock" &
    pid="$!"

    mysql=( mysql --protocol=socket -uroot -hlocalhost --socket="/tmp/mysql.sock" )
    for i in {60..0}; do
        if echo 'SELECT 1' | "${mysql[@]}" &> /dev/null; then
            break
        fi
        echo 'MySQL init process in progress...'
        sleep 1
    done
    if [ "$i" = 0 ]; then
        echo >&2 'MySQL init process failed.'
        exit 1
    fi
    if [ -z "$MYSQL_INITDB_SKIP_TZINFO" ]; then
        # sed is for https://bugs.mysql.com/bug.php?id=20545
        mysql_tzinfo_to_sql /usr/share/zoneinfo | sed 's/Local time zone must be set--see zic manual page/FCTY/' | "${mysql[@]}" mysql
    fi

    if [[ ! -z "$MYSQL_RANDOM_ROOT_PASSWORD" ]] &&  [[ -z $MYSQL_ROOT_PASSWORD ]]; then
        export MYSQL_ROOT_PASSWORD="$(echo $RANDOM | sha256sum | base64 | head -c 16)"
        echo "GENERATED ROOT PASSWORD: $MYSQL_ROOT_PASSWORD"
    fi

    rootCreate=
    # default root to listen for connections from anywhere
    if [[ ! -z "$MYSQL_ROOT_PASSWORD" ]] && [[ "$MYSQL_ROOT_HOST" != 'localhost' ]]; then
        # no, we don't care if read finds a terminating character in this heredoc
        # https://unix.stackexchange.com/questions/265149/why-is-set-o-errexit-breaking-this-read-heredoc-expression/265151#265151
        read -r -d '' rootCreate <<-EOSQL || true
            CREATE USER 'root'@'${MYSQL_ROOT_HOST}' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}' ;
            GRANT ALL ON *.* TO 'root'@'${MYSQL_ROOT_HOST}' WITH GRANT OPTION ;
EOSQL
    fi

    "${mysql[@]}" <<-EOSQL
        -- What's done in this file shouldn't be replicated
        --  or products like mysql-fabric won't work
        SET @@SESSION.SQL_LOG_BIN=0;
        DELETE FROM mysql.user WHERE user = '';
        SET PASSWORD FOR 'root'@'localhost'=PASSWORD('${MYSQL_ROOT_PASSWORD}') ;
        GRANT ALL ON *.* TO 'root'@'localhost' WITH GRANT OPTION ;
        ${rootCreate}
        DROP DATABASE IF EXISTS test ;
        FLUSH PRIVILEGES ;
EOSQL

    if [ ! -z "$MYSQL_ROOT_PASSWORD" ]; then
        mysql+=( -p"${MYSQL_ROOT_PASSWORD}" )
    fi

    if [ ! -z "$MYSQL_DATABASE" ]; then
        echo "CREATE DATABASE IF NOT EXISTS $MYSQL_DATABASE ;" | "${mysql[@]}"
        mysql+=( "$MYSQL_DATABASE" )
    fi
    
    # create custom user 
    if [[ ! -z "$MYSQL_USER" ]] && [[ ! -z "$MYSQL_USER_PASSWORD" ]]; then
        MYSQL_USER_HOST=${MYSQL_USER_HOST:-'%'}
        MYSQL_USER_DATABASE=${MYSQL_USER_DATABASE:-'*'}
        echo "CREATE USER '$MYSQL_USER'@'$MYSQL_USER_HOST' IDENTIFIED BY '$MYSQL_USER_PASSWORD' ;" | "${mysql[@]}"
        echo "GRANT ALL ON $MYSQL_USER_DATABASE.* TO '$MYSQL_USER'@'$MYSQL_USER_HOST' ;" | "${mysql[@]}"
    fi

    echo
    for f in $my_datadir/initdb.d/*; do
        case "$f" in
            *.sh)     echo "$0: running $f"; . "$f" ;;
            *.sql)    echo "$0: running $f"; "${mysql[@]}" < "$f"; echo ;;
            *.sql.gz) echo "$0: running $f"; gunzip -c "$f" | "${mysql[@]}"; echo ;;
            *)        echo "$0: ignoring $f" ;;
        esac
        echo
    done

    if ! kill -s TERM "$pid" || ! wait "$pid"; then
        echo >&2 'MySQL init process failed.'
        exit 1
    fi

    echo
    echo 'MySQL init process done. Ready for start up.'
    echo
    touch ${my_datadir}/initdb.lock
fi

exec "$@"
