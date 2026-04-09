PREFIX ?= /usr/local

install:
	@echo "Installing cli-tools to $(PREFIX)/bin..."
	@install -d $(PREFIX)/bin
	@for f in bin/*; do \
		install -m 755 "$$f" "$(PREFIX)/bin/$$(basename $$f)"; \
	done
	@echo "Done."

uninstall:
	@echo "Removing cli-tools from $(PREFIX)/bin..."
	@for f in bin/*; do \
		rm -f "$(PREFIX)/bin/$$(basename $$f)"; \
	done
	@echo "Done."

list:
	@ls -1 bin/

.PHONY: install uninstall list
