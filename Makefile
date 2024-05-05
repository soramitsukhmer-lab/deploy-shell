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
	docker buildx bake $(DOCKER_BAKE_FILE) $(DOCKER_BAKE_TARGETS) --load
	@echo

run: shell

shell:
	docker run -it --rm -v $(PWD):$(PWD) -w $(PWD) soramitsukhmer-lab/deploy-shell:dev

.PHONY: example
example: example/deploy

example/deploy:
	$(MAKE) -C example deploy

example/teardown:
	$(MAKE) -C example teardown

test:
	DEPLOYSHELL_FORCE_CLEANUP=1 DEPLOYSHELL_SKIP_UPDATE=1 docs/run.sh dev soramitsukhmer-lab/deploy-shell
