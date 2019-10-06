#!/bin/bash
source /etc/profile
if [ -z $VIP ];then
    echo 'ENV ${VIP} is not SET, Plz check!'
    exit 1
fi

# Define and create storage directory
etc_dir=${STORAGE_DIR:-/usr/local/haproxy/etc}
temp_dir=${etc_dir}/temp
back_dir=${etc_dir}/backup
mkdir -p ${back_dir} ${temp_dir}

# Define the configration file
current_cfg=${etc_dir}/${VIP}.cfg
backup_cfg=${back_dir}/${VIP}_$(date +%F-%H%M%S).cfg
temp_cfg=${temp_dir}/${VIP}.cfg

# Define file download configration
curl_bin=$(which curl)
cfg_manage_api=${CFG_GET_URL:-http://your_haporxy_download_svr/haproxy/}${VIP} # 这里需要根据配置管理服务的实际情况修改地址

# console log
report_log()
{
    echo "[$(date '+%F %H:%M:%S')] $*"
}

# backup current configration file
backup_cfg()
{
    if [ -f ${current_cfg} ];then
        cp -a ${current_cfg} ${backup_cfg} && \
        report_log "Backup ${current_cfg} to  ${backup_cfg} success." || \
        report_log "Backup ${current_cfg} to  ${backup_cfg} failed."
    else
        report_log "${current_cfg} is not exist, maybe the first release, skiped."
    fi
}

# update current configration file
cover_cfg()
{   if [ -f ${temp_cfg} ];then
        cp -a ${temp_cfg} ${current_cfg} && \
        report_log "Cover ${temp_cfg} to ${current_cfg} success." || (
        report_log "Cover ${temp_cfg} to ${current_cfg} failed."
        exit 1
        )
    else
        report_log "${temp_cfg} is not exist, Unknow Error, exited."
        exit 1
    fi
}

# download latest configration file from download svr
download_cfg()
{
    report_log "Starting Download configration file to ${temp_cfg} ..."
    ret_code=$(${curl_bin} -s --max-time 120 --retry 3 -w %{http_code} -o ${temp_cfg} ${cfg_manage_api})
    if [ $ret_code -eq 200 ] && [ $? -eq 0 ];then
        report_log "Download configration file ${temp_cfg} success."
    else
        report_log "Download configration file ${temp_cfg} failed."
        exit 1
    fi
}

# check the latest configration 
check_cfg()
{
    old_md5=$(test -f ${current_cfg} && md5sum ${current_cfg} | awk '{print $1}' 2>/dev/null )
    new_md5=$(md5sum ${temp_cfg}|awk '{print $1}')
    if [ "$old_md5" = "$new_md5" ];then
        report_log "The configuration file ${VIP}.cfg is the same, no need update."
        return 2
    fi
    if haproxy -c -W -f ${temp_cfg} >/dev/null ;then
        report_log "Configuration file ${temp_cfg} is valid."
        return 0
    else
        report_log "Configuration file ${temp_cfg} is invalid."
        return 1
    fi
}

download_cfg
if check_cfg;then
    backup_cfg 
    cover_cfg && \
    report_log "${current_cfg} is updated success!"
else
    exit $?
fi
