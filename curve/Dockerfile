FROM centos:7.5.1804

RUN yum install -y git nmp \
	&&  mkdir /data/ \
   	&&  git clone https://github.com/baidu/Curve.git /data/ \
   	&& cd /data/Curve \
   	&& ./control.sh start

CMD /data/Curve/control.sh run
