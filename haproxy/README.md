## 基于Docker RestAPI的Haproxy远程管理镜像
### 一、原理介绍
首先，需要构建一个Haporxy的中心配置管理服务，这里用于托管Haproxy的配置，并提供一个接口可以通过VIP拉取到对应的配置内容，比如：

```
curl -s --max-time 120 --retry 3 -w %{http_code} -o 192.168.1.100.cfg http://192.168.1.1/haproxy/192.168.1.100
```

然后，在本镜像里面集成了一个shell脚本 update_cfg.sh，用于拉取、比对、更新Haproxy的配置文件。

最后，通过中心管理平台调用Docker API远程执行容器里面的 update_cfg.sh来更新Haproxy配置，如果成功则调用Docker API发送kill信号重载Haproxy，完成配置的平滑更新。。

### 二、快速演示介绍
#### 1、快速拉起一个Nginx作为Haproxy配置下载服务：
```
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

# 请求测试，有上述内容即为成功
curl http://127.0.0.1/127.0.0.1
```

2、编写Python脚本：

`start.py`:
```
# -- coding: utf8 --
import docker
client = docker.DockerClient(version='1.40', base_url='tcp://127.0.0.1:2375')
client.images.pull('jagerzhang/haproxy:latest')
client.containers.run(image='haproxy-plus:latest', name='demo2', volumes={'/data/images/haproxy/etc': {
                      'bind': '/usr/local/haproxy/etc', 'mode': 'rw'}}, network_mode='host', environment=["VIP=127.0.0.1", "CFG_GET_URL=http://127.0.0.1/"], detach=True)
```
`update.py`:
```
# -- coding: utf8 --
import docker

class dockerApi():
    def __init__(self,ip,port=2375):
        self.base_url = 'tcp://%s:%s' % (ip,port)
        self.client = docker.DockerClient(
            version='1.40', base_url=self.base_url)
        
    def exec_cmd(self,container_name, cmd='echo ok',decode=True):
        container = self.client.containers.get(container_name)
        result = container.exec_run(
            cmd=cmd, detach=False, tty=True, stdin=True, stdout=True)
        ret_code = result.exit_code
        if decode:
            ret_info = result.output.decode()
        else:
            ret_info = result.output
        return ret_code, ret_info

    def send_kill(self, container_name):
        container = self.client.containers.get(container_name)
        container.kill('SIGUSR2')

# 定义haproxy宿主机IP，可以是多个
ld_list = ['127.0.0.1']
# 定义更新配置的命令
cmd = 'bash /opt/update_cfg.sh'
# 定义容器名称
container_name = 'demo2' 
# 开始更新
for i in ld_list:
    obj = dockerApi(i)
    ret_code,ret_info = obj.exec_cmd(container_name, cmd)
    print '%s exec %s ret_code is: %s, exec ret_info:' % (i, cmd, ret_code)
    print ret_info
    if int(ret_code) == 0:
        obj.send_kill(container_name)
```

3、拉起容器
`python start.py`

4、更新配置
`python update.py`

### 更多

详细介绍请访问： https://zhang.ge/5152.html
