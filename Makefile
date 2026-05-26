# ----- Makefile -----
#
#
BRANCH := $(shell git branch --show-current)
REMOTES := $(shell git remote)
.DEFAULT_GOAL := help

.PHONY: help push push-lease

help:
	@echo "Options:"
	@echo
	@echo "  make push         -> Performs a remote push to all branches"
	@echo "  make push-lease   -> Performs a remote push of all branches (lease mode)"


# ----- GIT PUSH -----
push:
	@echo "Push normal → branch: $(BRANCH)"
	@for remote in $(REMOTES); do \
		echo "  pushing to $$remote..."; \
		git push $$remote $(BRANCH); \
	done

push-lease:
	@echo "Push --force-with-lease → branch: $(BRANCH)"
	@for remote in $(REMOTES); do \
		echo "  pushing to $$remote..."; \
		git push --force-with-lease $$remote $(BRANCH); \
	done
