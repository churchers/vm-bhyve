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
RCDIR=$(PREFIX)/etc/rc.d
MANDIR=$(PREFIX)/man/man8
MKDIR=/bin/mkdir
CP=/bin/cp

PROG=vm
MAN=$(PROG).8

install:
	$(MKDIR) -p $(BINDIR)
	$(MKDIR) -p $(FILESDIR)
	$(INSTALL) -m $(BINMODE) $(PROG) $(BINDIR)/
	$(INSTALL) lib/* $(FILESDIR)/
	$(INSTALL) rc.d/* $(RCDIR)/
	rm -f $(MAN).gz
	gzip -k $(MAN)
	$(INSTALL) $(MAN).gz $(MANDIR)/
	rm -f $(MAN).gz

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
