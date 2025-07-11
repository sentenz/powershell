# SPDX-License-Identifier: Apache-2.0

ifneq (,$(wildcard .env))
	include .env
	export
endif

# Define Variables

IS_WINDOWS := $(findstring Windows_NT,$(OS))
POWERSHELL := powershell

# Define Targets

default: help

help:
ifeq ($(IS_WINDOWS),Windows_NT)
	@echo "TODO Implement Windows help script"
else
	@awk 'BEGIN {printf "TASK\n\tA collection of task runner used in this project.\n\n"}'
	@awk 'BEGIN {printf "USAGE\n\tmake $(shell tput -Txterm setaf 6)[target]$(shell tput -Txterm sgr0)\n\n"}' $(MAKEFILE_LIST)
	@awk '/^##/{c=substr($$0,3);next}c&&/^[[:alpha:]][[:alnum:]_-]+:/{print "$(shell tput -Txterm setaf 6)\t" substr($$1,1,index($$1,":")) "$(shell tput -Txterm sgr0)",c}1{c=0}' $(MAKEFILE_LIST) | column -s: -t
endif
.PHONY: help

## Initialize a software development workspace with requisites
bootstrap: setup
ifeq ($(IS_WINDOWS),Windows_NT)
	$(POWERSHELL) -File .\scripts\Bootstrap.ps1
else
	@bash ./scripts/bootstrap.sh
endif
.PHONY: bootstrap

## Configure all dependencies essential for development
setup:
ifeq ($(IS_WINDOWS),Windows_NT)
	$(POWERSHELL) -File .\scripts\Setup.ps1
else
	@bash ./scripts/setup.sh
endif
.PHONY: setup

## Remove development artifacts and restore the host to its pre-setup state
teardown:
ifeq ($(IS_WINDOWS),Windows_NT)
	@echo "TODO Implement Windows teardown script"
else
	@echo "TODO Implement Linux teardown script"
endif
.PHONY: teardown

## Install PSScriptAnalyzer PowerShell module
install-pwsh-analyzer:
ifeq ($(IS_WINDOWS),Windows_NT)
	$(POWERSHELL) -Command "Install-Module -Name PSScriptAnalyzer -Scope CurrentUser -Force -AllowClobber"
else
	@echo "TODO Implement Linux installation script for PSScriptAnalyzer"
endif
.PHONY: install-pwsh-analyzer

## Lint PowerShell scripts and modules using PSScriptAnalyzer
lint-pwsh-analyze:
ifeq ($(IS_WINDOWS),Windows_NT)
	$(POWERSHELL) -Command "Invoke-ScriptAnalyzer -Path $(@D) -Recurse -Severity Warning,Error | Out-String"
else
	@echo "TODO Implement Linux linting script for PowerShell"
endif
.PHONY: lint-pwsh-analyze
