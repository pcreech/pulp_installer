NAMESPACE := $(shell python -c 'import yaml; print(yaml.safe_load(open("galaxy.yml"))["namespace"])')
NAME := $(shell python -c 'import yaml; print(yaml.safe_load(open("galaxy.yml"))["name"])')
VERSION := $(shell python -c 'import yaml; print(yaml.safe_load(open("galaxy.yml"))["version"])')
MANIFEST := build/collections/ansible_collections/$(NAMESPACE)/$(NAME)/MANIFEST.json

ROLES := $(wildcard roles/*)
DOCS := $(wildcard docs/*/*) $(wildcard docs/*)
META := $(wildcard meta/*)
PLAYBOOKS := $(wildcard playbooks/*/*/*) $(wildcard playbooks/*/*) $(wildcard playbooks/*)
METADATA := galaxy.yml COPYRIGHT LICENSE README.md requirements.yml
DEPENDENCIES := $(METADATA) $(foreach ROLE,$(ROLES),$(wildcard $(ROLE)/*/*)) $(META) $(DOCS) $(PLAYBOOKS)

MOLECULE_SCENARIO ?= release-static
TOX_ENV ?= py37-ansible2.9-$(MOLECULE_SCENARIO)
PYTHON_VERSION = $(shell python -c 'import sys; print("{}.{}".format(sys.version_info.major, sys.version_info.minor))')
SANITY_OPTS =

default: help
help:
	@echo "Please use \`make <target>' where <target> is one of:"
	@echo "  help           to show this message"
	@echo "  info           to show infos about the collection"
	@echo "  lint           to run code linting"
	@echo "  sanity         to run santy tests"
	@echo "  test           to run molecule tests"
	@echo "  dist           to build the collection artifact"

info:
	@echo "Building collection $(NAMESPACE)-$(NAME)-$(VERSION)"
	@echo "  roles:\n $(foreach ROLE,$(notdir $(ROLES)),   - $(ROLE)\n)"

lint: $(MANIFEST)
	molecule lint --scenario-name $(MOLECULE_SCENARIO)

sanity: $(MANIFEST)
	# Fake a fresh git repo for ansible-test
	cd $(<D) ; git init ; echo tests > .gitignore ; ansible-test sanity $(SANITY_OPTS) --python $(PYTHON_VERSION)

test: $(MANIFEST)
	tox -e $(TOX_ENV)

$(MANIFEST): $(NAMESPACE)-$(NAME)-$(VERSION).tar.gz
	ansible-galaxy collection install -p build/collections $< --force

build/src/%: %
	install -m 644 -DT $< $@

$(NAMESPACE)-$(NAME)-$(VERSION).tar.gz: $(addprefix build/src/,$(DEPENDENCIES))
	ansible-galaxy collection build build/src --force

dist: $(NAMESPACE)-$(NAME)-$(VERSION).tar.gz

install: $(MANIFEST)

publish: $(NAMESPACE)-$(NAME)-$(VERSION).tar.gz
	ansible-galaxy collection publish --api-key $(GALAXY_API_KEY) $<

clean:
	rm -rf build

FORCE:

.PHONY: help dist install lint sanity test publish FORCE
