#
# vm-bhyve Makefile
#

PREFIX?=/usr/local
BINDIR=$(DESTDIR)$(PREFIX)/sbin
EXAMPLESDIR=$(DESTDIR)${PREFIX}/share/examples/vm-bhyve
LIBDIR=$(DESTDIR)$(PREFIX)/lib/vm-bhyve
MANDIR=$(DESTDIR)$(PREFIX)/man/man8
RCDIR=$(DESTDIR)$(PREFIX)/etc/rc.d

CP=/bin/cp
INSTALL=/usr/bin/install
LN=/bin/ln
MKDIR=/bin/mkdir

PROG=vm
MAN=$(PROG).8

install:
	$(MKDIR) -p $(BINDIR)
	$(INSTALL) -m 544 $(PROG) $(BINDIR)/

	$(MKDIR) -p $(LIBDIR)
	$(INSTALL) lib/* $(LIBDIR)/

	$(MKDIR) -p $(EXAMPLESDIR)
	$(INSTALL) sample-templates/* $(EXAMPLESDIR)/

	$(MKDIR) -p $(RCDIR)
	$(INSTALL) -m 555 rc.d/* $(RCDIR)/

	$(MKDIR) -p $(MANDIR)
	gzip -fk $(MAN)
	$(INSTALL) $(MAN).gz $(MANDIR)/
	rm -f -- $(MAN).gz
	$(LN) -sf $(MANDIR)/$(MAN).gz $(MANDIR)/vm-bhyve.8.gz

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
