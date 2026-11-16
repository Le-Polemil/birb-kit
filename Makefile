PREFIX ?= /usr/local
# Latest v* tag (v0.4.7, or v0.4.7-2-gabc1234 past it); empty outside a clone.
VERSION := $(shell git describe --tags --match 'v[0-9]*' 2>/dev/null)

install:
	@echo "Installing birb-kit to $(PREFIX)..."
	@install -d $(PREFIX)/bin
	@install -d $(PREFIX)/libexec
	@for f in bin/*; do \
		install -m 755 "$$f" "$(PREFIX)/bin/$$(basename $$f)"; \
	done
	@if [ -n "$(VERSION)" ]; then \
		sed "s|^BIRB_VERSION='\$$Format:.*|BIRB_VERSION='$(VERSION)'|" bin/birb > "$(PREFIX)/bin/birb.tmp" && \
		chmod 755 "$(PREFIX)/bin/birb.tmp" && \
		mv "$(PREFIX)/bin/birb.tmp" "$(PREFIX)/bin/birb"; \
	fi
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
