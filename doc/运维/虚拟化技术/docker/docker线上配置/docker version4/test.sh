#!/bin/bash
#dockerfile test scripy
#date: 2017-9-19
#author: huyuan

#judge dockerfile file Does it exist ?
if [ -f Dockerfile_systemlib.1 -a -f Dockerfile_pylib.2 -a -f Dockerfile_config.3 ];then
    echo 'yes' > /dev/null 
else
    exit 10
fi

#judge docker whether install ，whether exist ubuntu:16.04 iso
dockerrunenv() {
    which docker
    if [ $? -ne 0 ];then
        echo -e "\033[31m $1 please install docker_ce exit ... \033[0m"
        exit 30
    fi
    docker images | awk '{print $1,$2}' | grep -v TAG | grep 'ubuntu 16.04' &> /dev/null
    if [ $? -ne 0 ];then
        docker pull ubuntu:16.04
    fi
}

#running dockerfile
dockerfile() {
    cp $1 Dockerfile
    imgname=$(echo "$1" | awk -F'_' '{print $2}' | awk -F. '{print $1}')
    docker build -t="ubuntu:$imgname" .
    if [ $? -ne 0 ];then
        echo -e "\033[31m $1 running error exit... \033[0m"
        exit 20
   fi
   rm -rf Dockerfile
}

#running function
dockerrunenv

dockerfile Dockerfile_systemlib.1
dockerfile Dockerfile_pylib.2
dockerfile Dockerfile_config.3



