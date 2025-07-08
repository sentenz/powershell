# SPDX-License-Identifier: Apache-2.0

ifneq (,$(wildcard .env))
	include .env
	export
endif

# Define Variables

POWERSHELL = pwsh

# Define Targets

default: help

help:
	@awk 'BEGIN {printf "TASK\n\tA collection of task runner used in the current project.\n\n"}'
	@awk 'BEGIN {printf "USAGE\n\tmake $(shell tput -Txterm setaf 6)[target]$(shell tput -Txterm sgr0)\n\n"}' $(MAKEFILE_LIST)
	@awk '/^##/{c=substr($$0,3);next}c&&/^[[:alpha:]][[:alnum:]_-]+:/{print "$(shell tput -Txterm setaf 6)\t" substr($$1,1,index($$1,":")) "$(shell tput -Txterm sgr0)",c}1{c=0}' $(MAKEFILE_LIST) | column -s: -t
.PHONY: help

## Initialize a software development workspace with requisites
bootstrap:
	$(POWERSHELL) -File scripts/Bootstrap.ps1
.PHONY: bootstrap

## Install and configure all dependencies essential for development
setup:
	$(POWERSHELL) -File scripts/Setup.ps1
.PHONY: setup

## Remove development artifacts and restore the host to its pre-setup state
teardown:
	# TODO
.PHONY: teardown

## Install PSScriptAnalyzer PowerShell module
install-pwsh-analyzer:
	$(POWERSHELL) -Command "Install-Module -Name PSScriptAnalyzer -Scope CurrentUser -Force -AllowClobber"
.PHONY: install-pwsh-analyzer

## Lint PowerShell scripts and modules using PSScriptAnalyzer
lint-pwsh-analyze:
	@mkdir -p logs
	$(POWERSHELL) -Command "Invoke-ScriptAnalyzer -Path $(@D) -Recurse -Severity Warning,Error | Out-String" > logs/pwsh-lint.log 2>&1
.PHONY: lint-pwsh-analyze
