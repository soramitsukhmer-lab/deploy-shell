.EXPORT_ALL_VARIABLES:
NODE_VERSION := 20
DOCKER_BAKE_TARGETS := dev

.PHONY: it
it: print build

print:
	@echo "Bake definition:"
	@docker buildx bake --print $(DOCKER_BAKE_TARGETS)
	@echo

build:
	@echo "Buiding images:"
	docker buildx bake $(DOCKER_BAKE_FILE) $(DOCKER_BAKE_TARGETS)
	@echo

run:
	docker run -it --rm \
		-p 2222:22 \
		docker.io/chocolatefrappe/ssh-proxy-server:local

shell:
	docker run -it --rm docker.io/chocolatefrappe/ssh-proxy-server:local bash

.PHONY: example
example: example/deploy

example/deploy:
	$(MAKE) -C example deploy

example/teardown:
	$(MAKE) -C example teardown
