# -- coding: utf8 --
import docker
client = docker.DockerClient(version='1.40', base_url='tcp://127.0.0.1:2375')
client.images.pull('jagerzhang/haproxy:latest') # 本地测试，所以这里不需要拉取镜像
client.containers.run(image='haproxy-plus:latest', name='demo2', volumes={'/data/images/haproxy/etc': {
                      'bind': '/usr/local/haproxy/etc', 'mode': 'rw'}}, network_mode='host', environment=["VIP=127.0.0.1", "CFG_GET_URL=http://127.0.0.1/"], detach=True)
