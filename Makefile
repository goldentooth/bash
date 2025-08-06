BIN ?= goldentooth
PREFIX ?= /usr/local
AUTOCOMPLETE_DIR ?= $(HOME)/.local/share/bash-completion/completions
ANSIBLE_INVENTORY ?= $(HOME)/Projects/goldentooth/ansible/inventory/hosts

install:
	@echo "🔧 Parsing Ansible inventory for group definitions..."
	python3 parse-inventory.py $(ANSIBLE_INVENTORY) goldentooth-inventory.sh
	@echo "📦 Installing goldentooth CLI..."
	mkdir -p $(AUTOCOMPLETE_DIR)
	cp goldentooth.sh $(PREFIX)/bin/$(BIN)
	cp goldentooth-inventory.sh $(PREFIX)/bin/$(BIN)-inventory.sh
	cp autocomplete.sh $(AUTOCOMPLETE_DIR)/$(BIN)
	@echo "✅ Installation complete!"
	@echo "💡 SSH-based operations will use parsed inventory groups"
	@if ! command -v parallel >/dev/null 2>&1; then \
		echo "⚠️  Consider installing GNU parallel for faster group operations:"; \
		echo "   brew install parallel  # macOS"; \
		echo "   apt install parallel   # Ubuntu/Debian"; \
	fi

uninstall:
	rm -f $(PREFIX)/bin/$(BIN)
	rm -rf $(AUTOCOMPLETE_DIR)/$(BIN)
