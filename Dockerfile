from ubuntu_base

MAINTAINER Bit Bamboo, LLC "alext@bitbamboo.com"

RUN mkdir -p /home && mkdir -p /home/docker && mkdir -p /home/docker/run && mkdir -p /home/docker/logs

ENV BUILD 1
ENV LC_ALL en_US.UTF-8

#REQUIRES docker-proxy to be running on port 8096 for apt-cacher-ng
#Setup Proxies (Comment Out the following lines if your proxy is not set up)
#TODO: Make a clearer error message when proxy is not running
#apt-cacher-ng
#RUN /sbin/ip route | awk '/default/ { print "Acquire::http::Proxy \"http://"$3":8096\";" }' > /etc/apt/apt.conf.d/30proxy

# install java
RUN apt-get install -y wget openjdk-6-jre

# get logstash
RUN wget http://logstash.objects.dreamhost.com/release/logstash-1.1.13-flatjar.jar -O /opt/logstash.jar --no-check-certificate

# install our code
# add from repository root
ADD . /home/docker/code/

CMD ["/bin/bash", "/home/docker/code/server/startup.sh"]


