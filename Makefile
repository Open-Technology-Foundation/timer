# Makefile for timer - High-precision command timer

PREFIX      ?= /usr/local
BINDIR      ?= $(PREFIX)/bin
COMPDIR     ?= /usr/share/bash-completion/completions

USER_BINDIR  = $(HOME)/.local/bin
USER_COMPDIR = $(HOME)/.local/share/bash-completion/completions

SCRIPT      = timer
COMPLETION  = timer.bash-completion

.PHONY: install install-user uninstall uninstall-user help

help:
	@echo "Usage:"
	@echo "  make install        System install (requires sudo)"
	@echo "  make install-user   User install (~/.local)"
	@echo "  make uninstall      Remove system install"
	@echo "  make uninstall-user Remove user install"

install:
	install -d $(DESTDIR)$(BINDIR)
	install -m 755 $(SCRIPT) $(DESTDIR)$(BINDIR)/$(SCRIPT)
	install -d $(DESTDIR)$(COMPDIR)
	install -m 644 $(COMPLETION) $(DESTDIR)$(COMPDIR)/$(SCRIPT)

install-user:
	install -d $(USER_BINDIR)
	install -m 755 $(SCRIPT) $(USER_BINDIR)/$(SCRIPT)
	install -d $(USER_COMPDIR)
	install -m 644 $(COMPLETION) $(USER_COMPDIR)/$(SCRIPT)

uninstall:
	rm -f $(DESTDIR)$(BINDIR)/$(SCRIPT)
	rm -f $(DESTDIR)$(COMPDIR)/$(SCRIPT)

uninstall-user:
	rm -f $(USER_BINDIR)/$(SCRIPT)
	rm -f $(USER_COMPDIR)/$(SCRIPT)
