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
