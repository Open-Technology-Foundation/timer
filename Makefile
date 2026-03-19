# Makefile - Install timer
# BCS1212 compliant

PREFIX  ?= /usr/local
BINDIR  ?= $(PREFIX)/bin
MANDIR  ?= $(PREFIX)/share/man/man1
COMPDIR ?= /etc/bash_completion.d
DESTDIR ?=

USER_PREFIX  ?= $(HOME)/.local
USER_BINDIR  ?= $(USER_PREFIX)/bin
USER_MANDIR  ?= $(USER_PREFIX)/share/man/man1
USER_COMPDIR ?= $(HOME)/.local/share/bash-completion/completions

.PHONY: all install install-user uninstall uninstall-user check help

all: help

install:
	install -d $(DESTDIR)$(BINDIR)
	install -m 755 timer $(DESTDIR)$(BINDIR)/timer
	install -d $(DESTDIR)$(MANDIR)
	install -m 644 timer.1 $(DESTDIR)$(MANDIR)/timer.1
	@if [ -d $(DESTDIR)$(COMPDIR) ]; then \
	  install -m 644 timer.bash-completion $(DESTDIR)$(COMPDIR)/timer; \
	fi
	@if [ -z "$(DESTDIR)" ]; then $(MAKE) --no-print-directory check; fi

uninstall:
	rm -f $(DESTDIR)$(BINDIR)/timer
	rm -f $(DESTDIR)$(MANDIR)/timer.1
	rm -f $(DESTDIR)$(COMPDIR)/timer

install-user:
	install -d $(USER_BINDIR)
	install -m 755 timer $(USER_BINDIR)/timer
	install -d $(USER_MANDIR)
	install -m 644 timer.1 $(USER_MANDIR)/timer.1
	@if [ -d $(USER_COMPDIR) ]; then \
	  install -m 644 timer.bash-completion $(USER_COMPDIR)/timer; \
	fi

uninstall-user:
	rm -f $(USER_BINDIR)/timer
	rm -f $(USER_MANDIR)/timer.1
	rm -f $(USER_COMPDIR)/timer

check:
	@command -v timer >/dev/null 2>&1 \
	  && echo 'timer: OK' \
	  || echo 'timer: NOT FOUND (check PATH)'

help:
	@echo 'Usage: make [target]'
	@echo ''
	@echo 'Targets:'
	@echo '  install        Install to $(PREFIX) (requires sudo)'
	@echo '  install-user   Install to ~/.local/bin'
	@echo '  uninstall      Remove system install'
	@echo '  uninstall-user Remove user install'
	@echo '  check          Verify installation'
	@echo '  help           Show this message'
	@echo ''
	@echo 'Install from GitHub:'
	@echo '  git clone https://github.com/Open-Technology-Foundation/timer.git'
	@echo '  cd timer && sudo make install'
