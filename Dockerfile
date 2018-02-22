FROM docker:18.02-dind

LABEL Maintainer="Damien DUPORTAL <damien.duportal@gmail.com>"

ARG user=jenkins
ARG group=jenkins
ARG uid=1000
ARG gid=1000
ARG jenkins_user_home=/home/${user}

ENV JENKINS_USER_HOME=${jenkins_user_home} \
  LANG=C.UTF-8 \
  JAVA_HOME=/usr/lib/jvm/java-1.8-openjdk \
  PATH=${PATH}:/usr/local/bin:/usr/lib/jvm/java-1.8-openjdk/jre/bin:/usr/lib/jvm/java-1.8-openjdk/bin \
  DOCKER_IMAGE_CACHE_DIR=/docker-cache

RUN apk add --no-cache \
  bash \
  curl \
  ca-certificates \
  git \
  openjdk8 \
  py-pip \
  unzip \
  tar \
  tini

RUN addgroup -g ${gid} ${group} \
  && adduser \
    -h "${jenkins_user_home}" \
    -u "${uid}" \
    -G "${group}" \
    -s /bin/bash \
    -D "${user}" \
  && echo "${user}:${user}" | chpasswd

# Adding default user to the right groups
RUN addgroup docker \
  && addgroup ${user} docker \
  && addgroup ${user} dockremap

### Install LATEST stable Docker-compose
RUN pip install --no-cache-dir --upgrade pip \
  && pip install --no-cache-dir "docker-compose"

COPY ./daemon.json /etc/docker/daemon.json
COPY ./entrypoint.bash /usr/local/bin/entrypoint.bash

VOLUME ${jenkins_user_home} /docker-cache

WORKDIR ${jenkins_user_home}

ENTRYPOINT ["/sbin/tini","-g","--","bash","/usr/local/bin/entrypoint.bash"]
