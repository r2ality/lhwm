PREFIX     ?= /usr/local
BINDIR     ?= $(PREFIX)/bin
SYSCONFDIR ?= /etc

# holyc-lang compiler (https://github.com/Jamesbarford/holyc-lang).
# HCC_PREFIX is where hcc was installed (its include/ holds tos.HH and its
# lib/ holds libtos); it defaults to the standard /usr/local install.
HCC        ?= hcc
HCC_PREFIX ?= /usr/local
CLIBS       = -lX11 -lXinerama -lXrandr -lXcomposite -lXrender

BIN = holywm
SRC = holywm.HC

all: $(BIN)

$(BIN): $(SRC) xlib.HH
	$(HCC) --install-dir $(HCC_PREFIX) $(SRC) -clibs='$(CLIBS)' -o $(BIN)

install: $(BIN)
	mkdir -p $(DESTDIR)$(BINDIR)
	mkdir -p $(DESTDIR)$(SYSCONFDIR)/holywm
	install -m 755 $(BIN) $(DESTDIR)$(BINDIR)/$(BIN)
	install -m 644 config.conf $(DESTDIR)$(SYSCONFDIR)/holywm/config.conf

uninstall:
	rm -f $(DESTDIR)$(BINDIR)/$(BIN)
	rm -f $(DESTDIR)$(SYSCONFDIR)/holywm/config.conf

clean:
	rm -f $(BIN)

.PHONY: all install uninstall clean
