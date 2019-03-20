#!/usr/bin/env bash
set -eo pipefail
# get ipaddress
getip()
{
    bridges="br0 eth1 eth0 lo"
    for i in $bridges; do
        if [ `ifconfig | egrep "^${i}" | wc -l` -ne 0 ]; then
            echo `ip addr show ${i} | grep brd | grep inet | awk '{print $2}' | cut -d / -f1`
            break
        fi  
    done
}
# 初始化galera配置
galera_init()
{
    # port configuration
    gmcast_list_port=${gmcast_list_port:-1$my_port}
    ist_recv_port=${ist_recv_port:-2$my_port}
    sst_receive_port=${sst_receive_port:-3$my_port}
    # cluster join point address
    join_address=${join_address:-""}
    if ! echo  $join_address | grep ":";then
        if [[ ! -z $join_address  ]];then
            join_address=$join_address:$gmcast_list_port
        fi
    fi
    wsrep_cluster_name="${cluster_name:-cluster_name}"
    wsrep_cluster_address=gcomm://${join_address}
    wsrep_node_address=${wsrep_node_address:-$local_addr}
    wsrep_sst_auth=${wsrep_sst_auth:-"sst:${mysql_sst_password}"}
    gcache_size=${gcache_size:-5G}
    wsrep_provider_options="gcache.size=${gcache_size}; gmcast.listen_addr=tcp://${local_addr}:${gmcast_list_port}; ist.recv_addr=${local_addr}:${ist_recv_port};"
    wsrep_sst_receive_address=${local_addr}:${sst_receive_port}

cat <<- EOF > $wsrep_cnf
# Galera Cluster Auto Generated Config
[galera]
wsrep_on="${wsrep_on:-on}"
wsrep_provider="${wsrep_provider:-/usr/lib64/galera/libgalera_smm.so}"
wsrep_provider_options="${wsrep_provider_options}"
wsrep_cluster_address="${wsrep_cluster_address}"
wsrep_cluster_name="${cluster_name}"
wsrep_node_name="${wsrep_node_name:-$local_addr}"
wsrep_sst_auth="${wsrep_sst_auth}"
wsrep_sst_method="${wsrep_sst_method:-mariabackup}"
wsrep_sst_receive_address=${wsrep_sst_receive_address}
wsrep_node_address="${wsrep_node_address}"
EOF
}
# autoconf
auto_init()
{
    for VAR in $(env)
    do
    if [[ $VAR =~ ^my_  ]]; then
        mysql_conf_name=$(echo "$VAR" | sed -r 's/my_(.*)=.*/\1/g' | tr '[:upper:]' '[:lower:]')
        env_var=$(echo "$VAR" | sed -r 's/(.*)=//g')
        echo "set $mysql_conf_name=$env_var"
        if grep -E -q '(^|^#)'"$mysql_conf_name(\s+|)="  $mysql_cnf; then
            sed -r -i 's@(^|^#)('"$mysql_conf_name"')(\s+|)=(.*)@\2='"${env_var}"'@g' $mysql_cnf #note that no config values may contain an '@' char
        else
            echo "$mysql_conf_name=${env_var}" >> $mysql_cnf
        fi
    fi
    if [[ $VAR =~ ^wsrep_  ]]; then
        wsrep_conf_name=$(echo "$VAR" | sed -r 's/(.*)=.*/\1/g' | tr '[:upper:]' '[:lower:]')
        env_var=$(echo "$VAR" | sed -r 's/(.*)=//g')
        echo "set $wsrep_conf_name=$env_var"
        if grep -E -q '(^|^#)'"$wsrep_conf_name(\s+|)=" $wsrep_cnf; then
            sed -r -i 's@(^|^#)('"$wsrep_conf_name"')(\s+|)=(.*)@\2='"${env_var}"'@g' $wsrep_cnf #note that no config values may contain an '@' char
        else
            echo "$wsrep_conf_name=${env_var}" >> $wsrep_cnf
        fi
    fi
    done
}

export local_addr=$(getip)
export my_port=${my_port:-3307}
export cluster_mode=${cluster_mode:-1}
export my_server_id=${my_server_id-$(echo $local_addr | awk -F '.' '{print $3$4}')}
export base_dir=${base_dir:-/data/mariadb-galera}
export my_datadir=${my_datadir:-$base_dir/data}
export conf_dir=${conf_dir:-$base_dir/conf}
export lock_dir=${lock_dir:-$base_dir/lock}
export logs_dir=${logs_dir:-$base_dir/logs}
export my_log_error=$logs_dir/error.log
export my_slow_query_log_file=$logs_dir/slow.log
export my_pid_file=$lock_dir/mysql.pid
mkdir -p {$my_datadir,$lock_dir,$logs_dir,$conf_dir,$base_dir/initdb.d}
chown -R mysql:mysql {$my_datadir,$lock_dir,$logs_dir,$conf_dir,$base_dir/initdb.d}
export mysql_sst_password=${mysql_sst_password:-"${cluster_name}@${my_port}"}
# get memory_limit set , get MemTotal if  memory_limit is not set.
memory_total=$(awk '/MemTotal:/ {printf("%d", $2/1024)}' /proc/meminfo)
if [[ -f /sys/fs/cgroup/memory/memory.stat ]];then
    memory_limit_stat=$(awk '/hierarchical_memory_limit/ {printf("%d", $2/1024/1024)}' /sys/fs/cgroup/memory/memory.stat)
fi
if [[ $memory_total -gt $memory_limit_stat ]];then
    export memory_limit=$memory_limit_stat   
else
    export memory_limit=$memory_total
fi

# reserved custom configuration 
if [[ -f $conf_dir/custom.cfg ]];then
    source $conf_dir/custom.cfg
else
cat > $conf_dir/custom.cfg << EOF
# put some custom configuration in this file can change zhe container by yourself.
# Usage:
#      export cluster_name=new_cluster_name
#      unset node2
# 
EOF
fi

# in Cluster mode, will auto find members when the join_address is not set.
# force to skiped if cluster_mode set to 0.
if [[ -z $join_address ]] && [[ $cluster_mode -eq 1 ]];then
    echo "==================================== Auto-join Galera Cluster  ======================================="
    source /auto-join-cluster.sh
fi

wsrep_cnf=$conf_dir/wsrep.cnf
mysql_cnf=$conf_dir/server.cnf
if [[ ! -f $mysql_cnf ]]; then
    cp -a /etc/my.cnf.d/server.cnf.sample $mysql_cnf
fi

# innodb_buffer_pool_size
export my_innodb_buffer_pool_size="$(echo $memory_limit | awk '{printf("%d", $0*0.7)}')M"
# innodb_log_file_size
innodb_log_file_size=`echo $my_innodb_buffer_pool_size | awk '{printf("%d", $0*0.2)}'`
if [ $innodb_log_file_size -lt 64 ]; then
    innodb_log_file_size="64"    
elif [ $innodb_log_file_size -gt 2048 ]; then
    innodb_log_file_size="2048"
fi
export my_innodb_log_file_size=${innodb_log_file_size}M
# max_connections
max_connections=`echo $my_innodb_buffer_pool_size | awk '{printf("%d", $0/10)}'`
if [ $max_connections -lt 500 ]; then
    max_connections="500"
elif [ $max_connections -gt 16000 ]; then
    max_connections="16000"
fi
export my_max_connections=${my_max_connections:-$max_connections}
# report_host
export my_report_host=${my_report_host:-$local_addr:$my_port}

# Initialization
echo "==================================== Initialization Infomation ======================================="
if [[ $cluster_mode -eq 1 ]];then
    echo "cluster_name: $cluster_name"
    echo "current_node: $current_node:$my_port"
    echo "cluster_members: $current_node:$my_port,$(echo ${member_list[@]}|sed -r "s/\s+/:$my_port,/g"):$my_port"
    echo
else
    export wsrep_on="off"
fi

if [[ ! -f $lock_dir/global.lock ]];then
    echo ">> Start initialize configuration (Touch the file $lock_dir/global.lock can skiped)."
    galera_init
    auto_init                                                                                                                                                
else
    echo ">> Found the igore flag: $lock_dir/global.lock, just skip init !"
    echo
    echo ">> Delete it if your want init again in the next start time !"
fi
ln -sf $wsrep_cnf /etc/my.cnf.d/
ln -sf $mysql_cnf /etc/my.cnf.d/
echo "=================================== MySQL Deamon Runing Infomation ==================================="
# Support instance graceful exit
graceful_exit(){
    kill -SIGTERM `pgrep -n mysqld`
    while pgrep -n mysqld;do
        sleep 1
    done
}

trap "graceful_exit" SIGTERM
/docker-entrypoint.sh "$@" &
wait $!
