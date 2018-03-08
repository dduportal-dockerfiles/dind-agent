DOCKER_IMAGE_NAME ?= dind-agent
DOCKERHUB_USERNAME ?= dduportal
DOCKER_IMAGE_TEST_TAG ?= latest
#$(shell git rev-parse --short HEAD)#$(shell git rev-parse --short HEAD)
DOCKER_IMAGE_NAME_TO_TEST ?= $(DOCKERHUB_USERNAME)/$(DOCKER_IMAGE_NAME):$(DOCKER_IMAGE_TEST_TAG)
CURRENT_GIT_BRANCH ?= $(shell git rev-parse --abbrev-ref HEAD)

export DOCKER_IMAGE_NAME_TO_TEST

all: build test deploy

build:
	docker build \
		-t $(DOCKER_IMAGE_NAME_TO_TEST) \
		-f Dockerfile \
		$(CURDIR)/

test: build
	@echo "=== This is a Smoke Test:"
	docker run --rm --privileged=true $(DOCKER_IMAGE_NAME_TO_TEST) \
		DUMMY echo java -DHUDSON_HOME=jenkins -server -Xmx256m -Xms16m \
		-XX:+UseConcMarkSweepGC -Djava.net.preferIPv4Stack=true \
		-jar https://URL/slave.jar -secret SUPER_SECRET \
		-jnlpUrl https://URL/slave-agent.jnlp

deploy: test
	docker push $(DOCKER_IMAGE_NAME_TO_TEST)

.PHONY: all build test deploy
