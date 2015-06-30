#
#	Makefile
#

.include <bsd.own.mk>

PREFIX?= /usr/local
MAN=
BINOWN=		root
BINGRP=		wheel
BINMODE=	0500
BINDIR=$(PREFIX)/sbin
FILESDIR=$(PREFIX)/lib/vm-bhyve
RCDIR=$(PREFIX)/etc/rc.d
MANDIR=$(PREFIX)/man/man8
MKDIR=mkdir

PROG=	vm
MAN=	$(PROG).8

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

.MAIN: clean
clean: ;

.include <bsd.prog.mk>
