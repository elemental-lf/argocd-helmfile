# For docker build
export DOCKER_BUILDKIT=1
# For docker-compose
export COMPOSE_DOCKER_CLI_BUILD=1

.PHONY: build
build:
	docker buildx build -t elementalnet/`basename $$PWD` .;
	@version=$$(docker inspect -f {{.Config.Labels.version}} elementalnet/`basename $$PWD`); \
	if [ -n "$$version" ]; then \
	  docker tag elementalnet/`basename $$PWD`:latest elementalnet/`basename $$PWD`:$$version; \
	fi

.PHONY: test
test: build
	docker-compose -f docker-compose.test.yml up --build --no-start sut
	docker cp $(shell pwd)/goss `basename $$PWD`:/goss
	docker-compose -f docker-compose.test.yml up --no-recreate --exit-code-from sut --abort-on-container-exit sut

.PHONY: version
version:
	@docker inspect -f {{.Config.Labels.version}} elementalnet/`basename $$PWD`
