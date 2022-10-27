# Figure out which Zarf binary we should use based on the operating system we are on
ZARF_BIN := zarf
UNAME_S := $(shell uname -s)
UNAME_P := $(shell uname -p)
ifneq ($(UNAME_S),Linux)
	ifeq ($(UNAME_S),Darwin)
		ZARF_BIN := $(addsuffix -mac,$(ZARF_BIN))
	endif
	ifeq ($(UNAME_P),i386)
		ZARF_BIN := $(addsuffix -intel,$(ZARF_BIN))
	endif
	ifeq ($(UNAME_P),arm64)
		ZARF_BIN := $(addsuffix -apple,$(ZARF_BIN))
	endif
endif

# Optionally add the "-it" flag for docker run commands if the env var "CI" is not set (meaning we are on a local machine and not in github actions)
TTY_ARG :=
ifndef CI
	TTY_ARG := -it
endif

.DEFAULT_GOAL := help

# Use "silent mode" by default. Use `make <target> VERBOSE=1` to use verbose mode
ifndef VERBOSE
.SILENT:
endif

# Idiomatic way to force a target to always run, by having it depend on this dummy target
FORCE:

.PHONY: help
help: ## Show a list of all targets
	grep -E '^\S*:.*##.*$$' $(MAKEFILE_LIST) \
	| sed -n 's/^\(.*\): \(.*\)##\(.*\)/\1:\3/p' \
	| column -t -s ":"

all: | build/zarf build/zarf-mac-intel build/zarf-init-amd64-v0.22.2.tar.zst build/zarf-package-podinfo-amd64.tar.zst build/zarf-package-dos-games-amd64.tar.zst ## Build everything

#.PHONY: clean
#clean: ## Clean up build files
#	rm -rf ./build

.PHONY: vagrant-up
vagrant-up: ## Start the Vagrant VM
	VAGRANT_EXPERIMENTAL="disks" vagrant up --no-color
	vagrant ssh

vagrant-down: ## Destroy the Vagrant VM
	vagrant destroy -f

vagrant-ssh: ## SSH into the Vagrant VM
	vagrant ssh

vagrant-update: ## Update the Vagrant VM. Make sure it isn't running.
	vagrant box update

build:
	mkdir -p build

build/zarf: | build ## Download the Linux flavor of Zarf to the build dir
	echo "Downloading zarf"
	curl -sL https://github.com/defenseunicorns/zarf/releases/download/v0.22.2/zarf_v0.22.2_Linux_amd64 -o build/zarf
	chmod +x build/zarf

build/zarf-mac-intel: | build ## Download the Mac (Intel) flavor of Zarf to the build dir
	echo "Downloading zarf-mac-intel"
	curl -sL https://github.com/defenseunicorns/zarf/releases/download/v0.22.2/zarf_v0.22.2_Darwin_amd64 -o build/zarf-mac-intel
	chmod +x build/zarf-mac-intel

build/zarf-init-amd64-v0.22.2.tar.zst: | build ## Download the init package to the build dir
	echo "Downloading zarf-init-amd64-v0.22.2.tar.zst"
	curl -sL https://github.com/defenseunicorns/zarf/releases/download/v0.22.2/zarf-init-amd64-v0.22.2.tar.zst -o build/zarf-init-amd64-v0.22.2.tar.zst

build/zarf-package-podinfo-amd64.tar.zst: FORCE | build/$(ZARF_BIN) ## Build the podinfo package to the build dir
	echo "Creating zarf-package-podinfo-amd64.tar.zst"
	cd packages/podinfo && ../../build/$(ZARF_BIN) package create --confirm
	mv packages/podinfo/zarf-package-podinfo-amd64.tar.zst build/zarf-package-podinfo-amd64.tar.zst

build/zarf-package-dos-games-amd64.tar.zst: FORCE | build/$(ZARF_BIN) ## Build the game package to the build dir
	echo "Creating zarf-package-dos-games-amd64.tar.zst"
	cd packages/game && ../../build/$(ZARF_BIN) package create --confirm
	mv packages/game/zarf-package-dos-games-amd64.tar.zst build/zarf-package-dos-games-amd64.tar.zst
