SHELL := /bin/bash
.SHELLFLAGS := -euo pipefail -c
.DEFAULT_GOAL := help

.PHONY: help resolve build test test-plugins test-ios audit clean

help: ## List development targets
	@grep -E '^[a-zA-Z_-]+:.*?## ' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "%-16s %s\n", $$1, $$2}'

resolve: ## Resolve the single authoritative root dependency graph
	swift package resolve

build: ## Build all root-package source targets and plugins
	swift build

test: ## Run root unit tests without executing image snapshots
	swift test --skip PluginFixtureTests

test-plugins: ## Build the local plugin integration fixture from source
	swift test --filter PluginFixtureTests

test-ios: ## Compile and run the retained iOS snapshot fixture
	cd PrefireSnapshotTests && xcodebuild test \
		-scheme PrefireSnapshotTests-Package \
		-destination 'platform=iOS Simulator,name=iPhone 17' \
		-parallel-testing-enabled NO \
		-test-timeouts-enabled YES

audit: ## Validate lockfile and reject tracked binary artifacts
	Scripts/validate-lockfile.sh
	Scripts/verify-tracked-artifacts.sh

clean: ## Remove local build products only
	rm -rf .build PrefireSnapshotTests/.build
