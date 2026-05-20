# ----- Makefile -----
#
#
BRANCH := $(shell git branch --show-current)
.DEFAULT_GOAL := help

.PHONY: help commit push push-lease

help:
	@echo "Options:"
	@echo
	@echo "  make commit       -> Automatic commit"
	@echo "  make push         -> Performs a remote push to all branches"
	@echo "  make push-lease   -> Performs a remote push of all branches (lease mode)"


# ----- GIT -----
commit:
	@if ! git diff-index --quiet HEAD --; then \
		git add .; \
		git commit -m "$$(date +Date:%Y-%m-%d-Time:%H:%M:%S)"; \
	else \
		echo "Nothing to commit"; \
	fi

push:
	@echo "Push normal"
	@git push origin $(BRANCH)
	@git push hdd $(BRANCH)
	@git push lab $(BRANCH)

push-lease:
	@echo "Push com --force-with-lease"
	@git push --force-with-lease origin $(BRANCH)
	@git push --force-with-lease hdd $(BRANCH)
	@git push --force-with-lease lab $(BRANCH)
