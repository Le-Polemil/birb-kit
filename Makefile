PREFIX ?= /usr/local

install:
	@echo "Installing birb-kit to $(PREFIX)..."
	@install -d $(PREFIX)/bin
	@install -d $(PREFIX)/libexec
	@for f in bin/*; do \
		install -m 755 "$$f" "$(PREFIX)/bin/$$(basename $$f)"; \
	done
	@for f in libexec/*; do \
		install -m 755 "$$f" "$(PREFIX)/libexec/$$(basename $$f)"; \
	done
	@echo "Done."

uninstall:
	@echo "Removing birb-kit from $(PREFIX)..."
	@for f in bin/*; do \
		rm -f "$(PREFIX)/bin/$$(basename $$f)"; \
	done
	@for f in libexec/*; do \
		rm -f "$(PREFIX)/libexec/$$(basename $$f)"; \
	done
	@echo "Done."

list:
	@ls -1 libexec/ | sed 's/^birb-/  birb /'

.PHONY: install uninstall list
