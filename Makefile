# For docker build
export DOCKER_BUILDKIT=1
# For docker-compose
export COMPOSE_DOCKER_CLI_BUILD=1

.PHONY: build
build:
	docker build -t elementalnet/`basename $$PWD` .;
	@version=$$(docker inspect -f {{.Config.Labels.version}} elementalnet/`basename $$PWD`); \
		if [ -n "$$version" ]; then \
			docker tag elementalnet/`basename $$PWD`:latest elementalnet/`basename $$PWD`:$$version; \
		fi

.PHONY: check
check:
	@version=$$(docker inspect -f {{.Config.Labels.version}} elementalnet/`basename $$PWD`); \
		if [ -z "$$version" ]; then \
			echo "\033[91mError: version is not defined in Dockerfile.\033[0m"; \
			exit 1; \
		fi;
	@echo "\033[92mno problem.\033[0m";

.PHONY: test
test:
	docker-compose -f docker-compose.test.yml up --build --no-start sut
	docker cp $(shell pwd)/goss `basename $$PWD`:/goss
	docker-compose -f docker-compose.test.yml up --no-recreate --exit-code-from sut sut

.PHONY: push
push:
	@version=$$(docker inspect -f {{.Config.Labels.version}} elementalnet/`basename $$PWD`:latest); \
		if docker inspect --format='{{index .RepoDigests 0}}' elementalnet/$$(basename $$PWD):$$version >/dev/null 2>&1; then \
			echo "no changes"; \
		else \
			docker push elementalnet/`basename $$PWD`; \
		fi
