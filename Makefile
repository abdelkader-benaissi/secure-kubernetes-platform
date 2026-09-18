SHELL := /usr/bin/env bash
.DEFAULT_GOAL := help

.PHONY: help cluster bootstrap validate evidence clean
help:
	@printf '%s\n' 'cluster bootstrap validate evidence clean'
cluster:
	./scripts/create-kind.sh
bootstrap:
	./scripts/bootstrap.sh
validate:
	./scripts/validate.sh
evidence:
	./scripts/collect-evidence.sh
clean:
	kind delete cluster --name secure-platform
