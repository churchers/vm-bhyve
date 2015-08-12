#
# vm-bhyve Makefile
#

PREFIX?=/usr/local
MAN=
BINOWN=root
BINGRP=wheel
BINMODE=0500
BINDIR=$(PREFIX)/sbin
FILESDIR=$(PREFIX)/lib/vm-bhyve
EXAMPLESDIR=${PREFIX}/share/examples/vm-bhyve
RCDIR=$(PREFIX)/etc/rc.d
MANDIR=$(PREFIX)/man/man8
MKDIR=/bin/mkdir
CP=/bin/cp

PROG=vm
MAN=$(PROG).8

install:
	$(MKDIR) -p $(BINDIR)
	$(MKDIR) -p $(FILESDIR)
	$(MKDIR) -p $(EXAMPLESDIR)
	$(INSTALL) -m $(BINMODE) $(PROG) $(BINDIR)/
	$(INSTALL) lib/* $(FILESDIR)/
	$(INSTALL) sample-templates/* $(EXAMPLESDIR)/
	$(INSTALL) rc.d/* $(RCDIR)/
	rm -f $(MAN).gz
	gzip -k $(MAN)
	$(INSTALL) $(MAN).gz $(MANDIR)/

vmdir:
	@if [ -z "${PATH}" ]; then \
		echo "Usage: make vmdir PATH=/path"; \
	else \
		${MKDIR} -p "${PATH}/.templates"; \
		${MKDIR} -p "${PATH}/.iso"; \
		${MKDIR} -p "${PATH}/.config"; \
		${CP} sample-templates/* "${PATH}/.templates/"; \
	fi;

.MAIN: clean
clean: ;
