# agent-html-reports — Claude Code skill for polished HTML reports
#
# This Makefile installs the repo's skills into the user's Claude Code config
# directory (~/.claude/skills/) via symlinks, mirroring the incunabula pattern.

REPO_DIR    := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
CLAUDE_HOME := $(HOME)/.claude
SKILL_DST   := $(CLAUDE_HOME)/skills

.DEFAULT_GOAL := help
.PHONY: help install uninstall doctor refresh-references

help: ## Show this help
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} \
		/^[a-zA-Z_-]+:.*?##/ { printf "  \033[36m%-22s\033[0m %s\n", $$1, $$2 } \
		/^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) }' $(MAKEFILE_LIST)

##@ Install

install: ## Fetch upstream exemplars and symlink skills into ~/.claude/skills/
	@bash $(REPO_DIR)/skills/html-reports/install-references.sh
	@mkdir -p "$(SKILL_DST)"
	@for d in $(REPO_DIR)/skills/*/; do \
	  src=$${d%/}; \
	  ln -sfn "$$src" "$(SKILL_DST)/$$(basename $$src)"; \
	  echo "  ✓ $$(basename $$src) → $$src"; \
	done
	@echo "✓ skills → $(SKILL_DST)/<name>"

uninstall: ## Remove only the symlinks that point into this repo
	@for d in $(REPO_DIR)/skills/*/; do \
	  expected=$${d%/}; \
	  link="$(SKILL_DST)/$$(basename $$expected)"; \
	  if [ -L "$$link" ] && [ "$$(readlink "$$link")" = "$$expected" ]; then \
	    rm "$$link"; \
	    echo "  ✓ removed $$(basename $$expected)"; \
	  fi; \
	done
	@echo "✓ uninstalled"

doctor: ## Report install state (symlinks present, stale, or missing)
	@echo "agent-html-reports install check"
	@echo "  repo: $(REPO_DIR)"
	@echo
	@echo "Skills ($(SKILL_DST)):"
	@for d in $(REPO_DIR)/skills/*/; do \
	  expected=$${d%/}; \
	  name=$$(basename $$expected); \
	  link="$(SKILL_DST)/$$name"; \
	  if [ -L "$$link" ] && [ "$$(readlink "$$link")" = "$$expected" ]; then \
	    echo "  ✓ $$name"; \
	  else \
	    echo "  ✗ $$name  (not installed or stale)"; \
	  fi; \
	done

##@ Maintenance

refresh-references: ## Re-clone upstream and refresh skills/html-reports/references/
	@bash $(REPO_DIR)/skills/html-reports/install-references.sh
