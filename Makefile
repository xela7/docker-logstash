# Makefile for managing the GlobAllomeTree dockers

#  := evaluated later when run or used
#   = evaluated immediately when encountered by parser

SHELL := /bin/bash
PROJECT_ROOT := $(shell pwd)

deploy: clean install-utilities build sleep10 run

build: build-ubuntu-base build-elasticsearch build-logstash

clean: clean-elasticsearch clean-logstash clean-kibana

run: clean run-elasticsearch run-logstash run-kibana
	@echo
	@echo "Kibana + Logstash should now be running at http:/127.0.0.1/"
	@echo

stop: stop-logstash stop-elasticsearch

run-cache-server:
	#http://ftp.gnu.org/old-gnu/Manuals/make-3.79.1/html_chapter/make_toc.html#TOC50
	cd ../docker-cache && $(MAKE) run

########################################### UTILITIES ############################################

sleep10:
	sleep 10

sleep20:
	sleep 20

echo-vars:
	@echo "PROJECT_ROOT = '${PROJECT_ROOT}'"

########################################### UBUNTU BASE IMAGE #########################################

build-ubuntu-base:
	docker build -t ubuntu_base github.com/xela7/docker-ubuntu-base

########################################### logstash #########################################

clean-logstash:
	-@docker stop logstash 2>/dev/null || true
	-@docker rm logstash 2>/dev/null || true

build-logstash:
	docker build -t logstash_image .

run-logstash: clean-logstash
	#Run logstash on port 9300
	docker run -d -name logstash -p 8097:9300 -e ES_HOST=127.0.0.1 -e ES_PORT=9300 logstash_image

stop-logstash:
	docker stop logstash

attach-logstash:
	#Use lxc attach to attch to the webserver
	$(MAKE) dock-attach CONTAINER=logstash


########################################### kibana #########################################

clean-kibana:
	-@docker stop kibana 2>/dev/null || true
	-@docker rm kibana 2>/dev/null || true

build-kibana:
	docker build -t kibana_image .

run-kibana: clean-kibana
	#Run kibana on port 8082 forwarding to 80
	docker run -d -name kibana -p 8082:80 -e ES_HOST=127.0.0.1 -e ES_PORT=9200 kibana_image

stop-kibana:
	docker stop kibana

attach-kibana:
	#Use lxc attach to attch to the webserver
	$(MAKE) dock-attach CONTAINER=kibana


############################################# ELASTICSEARCH  #############################################

clean-elasticsearch:
	-@docker stop elasticsearch_server 2>/dev/null || true
	-@docker rm elasticsearch_server 2>/dev/null || true

build-elasticsearch:
	docker build -t elasticsearch_server_image github.com/GlobAllomeTree/docker-elasticsearch


run-elasticsearch: clean-elasticsearch
	sudo mkdir -p /opt/
	sudo mkdir -p /opt/data/
	sudo mkdir -p /opt/data/elasticsearch
	docker run -d -name elasticsearch_server -p 9200:9200 -v /opt/data/elasticsearch:/var/lib/elasticsearch elasticsearch_server_image


stop-elasticsearch:
	docker stop elasticsearch_server

run-elasticsearch-bash:
	-@docker stop elasticsearch_server_bash 2>/dev/null || true
	-@docker rm elasticsearch_server_bash 2>/dev/null || true
	docker run -i -t -name elasticsearch_server_bash -p 9200:9200 -v /opt/data/elasticsearch:/var/lib/elasticsearch elasticsearch_server_image /bin/bash


############################################ DOCKER SHORTCUTS ##########################################

stop-all-containers:
	docker stop `docker ps -notrunc -q`

#http://stackoverflow.com/questions/17236796/how-to-remove-old-docker-io-containers
#TODO: Add a confirm here
remove-all-containers:
	docker rm `docker ps -notrunc -a -q`

#http://jimhoskins.com/2013/07/27/remove-untagged-docker-images.html
#TODO: Add a confirm here
remove-untagged-images:	
	docker rmi `docker images | grep "^<none>" | awk "{print $3}"`

#http://techoverflow.net/blog/2013/10/22/docker-remove-all-images-and-containers/
#TODO: Add a confirm here
remove-all-images: 
	docker rmi $(docker images -q)

reset-docker: remove-all-containers remove-all-images
	#other things we can reset?

dock-attach:
	#Example) dock-attach CONTAINER=web_server
	#Example) make dock-attach CONTAINER=c1997df1e28
	sudo lxc-attach -n $(shell sudo docker inspect ${CONTAINER} | grep '"ID"' | sed 's/[^0-9a-z]//g') /bin/bash


########################### LOCAL UTILITIES FOR USE IN BUILDING IMAGES ############################ 

#	All of these local commands assume that you have the following repositories checked out in parent dir
#   ..
#   ../docker-elasticsearch  
#   ../docker-ubuntu-base
#   ../docker-logstash
#

# TODO: Get this working.  why add-docker-repo?
# install-utilities: add-docker-repo apt-update
install-utilities: apt-update
	sudo apt-get install -y git 

apt-update:
	sudo apt-get update

apt-upgrade:
	sudo apt-get upgrade

create-pip-cache-dir:
	sudo mkdir -p /opt &&
	sudo mkdir -p /opt/cache
	sudo mkdir -p /opt/cache/pip
	sudo chown ${USER}.${USER} /opt/cache/pip

run-pip-cache:
	python -m pypicache.main  --port 8090 /opt/cache/pip

install-docker: add-docker-repo
	sudo apt-get install lxc-docker

add-docker-repo:
	sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 36A1D7869245C8950F966E92D8576A8BA88D21E9
	sudo "echo deb http://get.docker.io/ubuntu docker main" > /tmp/docker.list
	sudo cp /tmp/docker.list /etc/apt/sources.list.d/

build-elasticsearch-local:
	docker build -t elasticsearch_server_image ../docker-elasticsearch

build-logstash-local: build-logstash
	
git-pull-all:
	@echo
	@tput setaf 6 && echo "--------------- Logstash ----------------" && tput sgr0
	git pull
	
	@echo
	@tput setaf 6 && echo "--------------- Kibana ----------------" && tput sgr0
	cd ../docker-kibana && git pull
	
	@echo
	@tput setaf 6 && echo "--------------- ElasticSearch Docker ----------------" && tput sgr0
	cd ../docker-elasticsearch && git pull
	
	@echo
	@tput setaf 6 && echo "--------------- Ubuntu Base Docker ----------------" && tput sgr0
	cd ../docker-ubuntu-base && git pull

git-push-all:
	@echo
	@tput setaf 6 && echo "--------------- Logstash ----------------" && tput sgr0
	git push
		
	@echo
	@tput setaf 6 && echo "--------------- Kibana ----------------" && tput sgr0
	cd ../docker-kibana && git push
	
	@echo
	@tput setaf 6 && echo "--------------- ElasticSearch Docker ----------------" && tput sgr0
	cd ../docker-elasticsearch && git push
	
	@echo
	@tput setaf 6 && echo "--------------- Ubuntu Base Docker ----------------" && tput sgr0
	cd ../docker-ubuntu-base && git push

git-status-all:
	@echo
	@tput setaf 6 && echo "--------------- Logstash ----------------" && tput sgr0
	git status
	
	@echo
	@tput setaf 6 && echo "--------------- Kibana ----------------" && tput sgr0
	cd ../docker-kibana && git status
	
	@echo
	@tput setaf 6 && echo "--------------- ElasticSearch Docker ----------------" && tput sgr0
	cd ../docker-elasticsearch && git status
	
	@echo
	@tput setaf 6 && echo "--------------- Ubuntu Base Docker ----------------" && tput sgr0
	cd ../docker-ubuntu-base && git status



