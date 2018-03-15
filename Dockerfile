# Official Docker Image from https://hub.docker.com/_/docker/
# Set the docker version you want to use
FROM docker:18.02-dind

LABEL Maintainer="Damien DUPORTAL <damien.duportal@gmail.com>"

# Defining default variables and build arguments
ARG user=jenkins
ARG group=jenkins
ARG uid=1000
ARG gid=1000
ARG jenkins_user_home=/home/${user}

ENV JENKINS_USER_HOME=${jenkins_user_home} \
  LANG=C.UTF-8 \
  JAVA_HOME=/usr/lib/jvm/java-1.8-openjdk \
  PATH=${PATH}:/usr/local/bin:/usr/lib/jvm/java-1.8-openjdk/jre/bin:/usr/lib/jvm/java-1.8-openjdk/bin \
  DOCKER_IMAGE_CACHE_DIR=/docker-cache \
  AUTOCONFIGURE_DOCKER_STORAGE=true

# Install required packages for running a Jenkins agent
RUN apk add --no-cache \
  bash \
  bats \
  curl \
  ca-certificates \
  git \
  make \
  openjdk8 \
  openssh-client \
  py-pip \
  unzip \
  tar \
  tini

# Set up default user for jenkins
RUN addgroup -g ${gid} ${group} \
  && adduser \
    -h "${jenkins_user_home}" \
    -u "${uid}" \
    -G "${group}" \
    -s /bin/bash \
    -D "${user}" \
  && echo "${user}:${user}" | chpasswd

# Adding the default user to groups used by docker engine
# "docker" for avoiding sudo, and "dockremap" if you enable user namespacing
RUN addgroup docker \
  && addgroup ${user} docker \
  && addgroup ${user} dockremap

### Install LATEST stable Docker-compose
RUN pip install --no-cache-dir --upgrade pip \
  && pip install --no-cache-dir "docker-compose"


# Custom start script
COPY ./entrypoint.bash /usr/local/bin/entrypoint.bash

# Those folders should not be on the Docker "layers"
VOLUME ${jenkins_user_home} /docker-cache /tmp

# Default working directory
WORKDIR ${jenkins_user_home}

# Define the "default" entrypoint command executed on the container as PID 1
ENTRYPOINT ["/sbin/tini","-g","--","bash","/usr/local/bin/entrypoint.bash"]
