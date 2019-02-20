#!/bin/bash
getip()
{
    bridges="br0 eth1 eth0"
    for i in $bridges; do
        if [ `ifconfig | egrep "^${i}" | wc -l` -ne 0 ]; then
            echo `ip addr show ${i} | grep brd | grep inet | awk '{print $2}' | cut -d / -f1`
            break
        fi  
    done
}

local_addr=$(getip)

check_node_status()
{
    check_node=$1
    check_port=$2
    if  echo 'a'|telnet -e 'a' $check_node $check_port >/dev/null 2>&1 ;then
        echo ">> $check_node is ready, start join cluster "
        export node_is_ready=1
    else
        if [[ "$current_node" != "$node1" ]];then
            echo ">> $check_node is not ready, retry check..."
        fi
        export node_is_ready=0
        sleep 1
    fi
}

node=1
member_list=()
for VAR in $(env|awk 'BEGIN{srand()}{b[rand()NR]=$0}END{for(x in b)print b[x]}')
    do
    if [[ $VAR =~ ^node  ]]; then
        node_name=$(echo "$VAR" | sed -r 's/(.*)=.*/\1/g' | tr '[:upper:]' '[:lower:]')
        env_var=$(echo "$VAR" | sed -r 's/(.*)=//g')
        if [[ "$env_var" != "$local_addr" ]];then
            member_list[$node]=$env_var
            let node+=1
            continue
        fi
        export current_node=$env_var
    fi
done
export member_list
round=0
while true;do
    if [[ "$current_node" == "$node1" ]] && [[ $round -eq 1 ]];then
        echo ">> Can't found any activated node, It's maybe the first one, just start without join_address."
        export first_start=1
        break
    fi
    for node in ${member_list[@]};do
        check_node_status $node $my_port
        if [[ $node_is_ready -eq 1 ]];then
            export join_address=$node
            break 2
        fi
    done
    let round+=1
done
