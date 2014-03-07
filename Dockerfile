from ubuntu_base

MAINTAINER Bit Bamboo, LLC "alext@bitbamboo.com"

RUN mkdir -p /home && mkdir -p /home/docker && mkdir -p /home/docker/run && mkdir -p /home/docker/logs

ENV BUILD 1
ENV LC_ALL en_US.UTF-8

#REQUIRES docker-proxy to be running on ports 8095 for pypi and 8096 for apt-cacher-ng
#Setup Proxies (Comment Out the following lines if your proxy is not set up)
#TODO: Make a clearer error message when proxy is not running
#apt-cacher-ng
RUN /sbin/ip route | awk '/default/ { print "Acquire::http::Proxy \"http://"$3":8096\";" }' > /etc/apt/apt.conf.d/30proxy
#pypi
ENV PIP_CONFIG_FILE /home/docker/pip.conf
RUN echo "[global]" > /home/docker/pip.conf
RUN /sbin/ip route | awk '/default/ { print "index-url = http://"$3":8095/simple" }' >> /home/docker/pip.conf
RUN cat /home/docker/pip.conf

# install uwsgi now because it takes a little while
RUN pip install uwsgi==2.0

# install nginx
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y nginx

# install our code
# add from repository root
ADD . /home/docker/code/ 

# setup all the configfiles
RUN echo "daemon off;" >> /etc/nginx/nginx.conf
RUN rm /etc/nginx/sites-enabled/default
RUN ln -s /home/docker/code/server/nginx.conf /etc/nginx/sites-enabled/
RUN ln -s /home/docker/code/server/supervisor.conf /etc/supervisor/conf.d/

CMD ["/bin/bash", "/home/docker/code/server/startup.sh"]