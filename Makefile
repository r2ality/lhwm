PREFIX ?= /usr/local
BINDIR ?= $(PREFIX)/bin
SYSCONFDIR ?= /etc
XSESSIONS ?= /usr/share/xsessions
HCC ?= hcc
HCC_PREFIX ?= /usr/local
BUILD_DIR ?= build
BIN := $(BUILD_DIR)/lhwm

.PHONY: all build check install uninstall clean install-session

all: build

build: $(BIN)

$(BIN): src/lhwm.HC src/x11.HH
	HCC='$(HCC)' HCC_PREFIX='$(HCC_PREFIX)' ./scripts/build.sh '$(BIN)'

check:
	./scripts/smoke-check.sh

install: $(BIN)
	install -d '$(DESTDIR)$(BINDIR)' '$(DESTDIR)$(SYSCONFDIR)/lhwm' '$(DESTDIR)$(XSESSIONS)'
	install -m 755 '$(BIN)' '$(DESTDIR)$(BINDIR)/lhwm'
	install -m 644 config/lhwm.conf '$(DESTDIR)$(SYSCONFDIR)/lhwm/lhwm.conf'
	sed -e 's|@BINDIR@|$(BINDIR)|g' -e 's|@DEFAULT_CONFIG@||g' scripts/lhwm-session.in > '$(DESTDIR)$(BINDIR)/lhwm-session'
	chmod 755 '$(DESTDIR)$(BINDIR)/lhwm-session'
	sed 's|@BINDIR@|$(BINDIR)|g' sessions/lhwm.desktop.in > '$(DESTDIR)$(XSESSIONS)/lhwm.desktop'

install-session: install

uninstall:
	rm -f '$(DESTDIR)$(BINDIR)/lhwm' '$(DESTDIR)$(BINDIR)/lhwm-session'
	rm -f '$(DESTDIR)$(XSESSIONS)/lhwm.desktop'
	rm -f '$(DESTDIR)$(SYSCONFDIR)/lhwm/lhwm.conf'

clean:
	rm -rf '$(BUILD_DIR)'
