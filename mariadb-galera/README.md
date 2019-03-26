Mariadb Galera Cluster 集群镜像（下面简称MGC），仅支持Host网络模式。
### 相比官方镜像的改进点：
- 一键式下发，无人值守创建MGC集群；
- 支持MySQL（包含galera）全局任意参数设置；
- 支持镜像之外的任何自定义脚本，支持sh、sql、gz、env等；
- 成员节点故障恢复后自动探测，找到可用点后重新加入集群；
- 支持集群、单点以及普通三种模式，可以覆盖各种关系存储场景；
- 支持数据库初始化自定义设置，包含root、自定义账号、数据库、密码、主机等相关信息;
- 支持节点恢复时的传输限速（单位KB/s），解决官方镜像恢复顶满带宽问题，支持rsync / mariadbbackup2种同步方式限速。

### 使用方法：
#### 集群模式启动必须传入的参数
- my_port 默认3307，其他galera通信端口将使用前面加1、加2、加3约定规则，比如 gcast 采用13307。
- node1=192.168.1.100
- node2=192.168.1.101
- node3=192.168.1.102

#### 目前已支持的参数
- mysql_user                 创建用户
- mysql_user_database 用户权限DB
- mysql_user_password 用户密码
- mysql_user_grand       grand权限
- mysql_database          创建数据库
- mysql_root_host          root可远程的主机
- mysql_root_password root密码
- mysql_random_root_password 随机密码
- transfer_limit             传输限速，单位 kb/s
- cluster_name   集群名字
- cluster_mode   是否使用集群模式
- join_address     指定已存在的成员IP

#### 支持任意mysql、galera参数
MySQLl参数使用my_${参数名} 形式，比如：my_tmp_talbe_size=512M
Galera参数使用wsrep_${参数名} 形式，比如：wsrep_sst_method=rsync

#### 快速启动demo
在192.168.1.100、192.168.1.101、192.168.1.102三个节点上分别执行如下命令即可（不要求先后，会自动组建集群）：
```
docker run -d \
    --net=host \
    --name=demo \
    -e cluster_name=demo \
    -e my_port=3310 \
    -e node1=192.168.1.100 \
    -e node2=192.168.1.101 \
    -e node3=192.168.1.102 \
    -e mysql_user=demo \
    -e mysql_user_password=123456 \
    -v /data/mariadb-galera:/data/mariadb-galera \
   jagerzhang/mariadb-galera
```
执行后，可以执行 docker logs -f demo-3310 查看启动日志，也可以执行 tail -f /data/mariadb-galera/logs/error.log 查看运行日，启动成功后，可以执行如下命令查看集群状态：

`mysql -h192.168.1.100 -P3310 -udemo -p123456 -e "show status like '%wsrep%'"`

#### 其他说明
待续...
