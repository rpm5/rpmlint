#############################################################################
# File		: Makefile
# Package	: rpmlint
# Author	: Frederic Lepied
# Created on	: Mon Sep 30 13:20:18 1999
# Version	: $Id$
# Purpose	: rules to manage the files.
#############################################################################

BINDIR=/usr/bin
LIBDIR=/usr/share/rpmlint
ETCDIR=/etc
MANDIR=/usr/share/man

FILES = rpmlint *.py INSTALL README README.devel COPYING \
	Makefile config rpmdiff rpmlint.bash-completion rpmlint.1
GENERATED = AUTHORS ChangeLog

PACKAGE=rpmlint

# update this variable to create a new release
VERSION := 0.77
TAG := $(shell echo "V$(VERSION)" | tr -- '-.' '__')
SVNBASE = $(shell svn info . | grep URL | sed -e 's/[^:]*:\s*//' -e 's,/\(trunk\|tags/.\+\)$$,,')

# for the [A-Z]* part 
LC_ALL:=C
export LC_ALL

all:
	python ./compile.py "$(LIBDIR)/" [A-Z]*.py
	@for f in [A-Z]*.py; do if grep -q '^[^#]*print ' $$f; then echo "print statement in $$f:"; grep -Hn '^[^#]*print ' $$f; exit 1; fi; done

clean:
	rm -f *~ *.pyc *.pyo AUTHORS ChangeLog

install:
	-mkdir -p $(DESTDIR)$(LIBDIR) $(DESTDIR)$(BINDIR) $(DESTDIR)$(ETCDIR)/$(PACKAGE) $(DESTDIR)$(ETCDIR)/bash_completion.d $(DESTDIR)$(MANDIR)/man1
	cp -p *.py *.pyo $(DESTDIR)$(LIBDIR)
	rm -f $(DESTDIR)$(LIBDIR)/compile.py*
	if [ -z "$(POLICY)" ]; then \
	  sed -e 's/@VERSION@/$(VERSION)/' < rpmlint.py > $(DESTDIR)$(LIBDIR)/rpmlint.py ; \
	else \
	  sed -e 's/@VERSION@/$(VERSION)/' -e 's/policy=None/policy="$(POLICY)"/' < rpmlint.py > $(DESTDIR)$(LIBDIR)/rpmlint.py; \
	fi
	cp -p rpmlint rpmdiff $(DESTDIR)$(BINDIR)
	cp -p config $(DESTDIR)$(ETCDIR)/$(PACKAGE)
	cp -p rpmlint.bash-completion $(DESTDIR)$(ETCDIR)/bash_completion.d/rpmlint
	cp -p rpmlint.1 $(DESTDIR)$(MANDIR)/man1/rpmlint.1

verify:
	pychecker *.py

version:
	@echo "$(VERSION)"


dist: cleandist localcopy tar

cleandist:
	rm -rf $(PACKAGE)-$(VERSION) $(PACKAGE)-$(VERSION).tar.bz2

localcopy: $(FILES) $(GENERATED)
	mkdir $(PACKAGE)-$(VERSION)
	cp -p $(FILES) $(GENERATED) $(PACKAGE)-$(VERSION)

tar: localcopy
	tar cv --owner=root --group=root -f $(PACKAGE)-$(VERSION).tar $(PACKAGE)-$(VERSION)
	bzip2 -9vf $(PACKAGE)-$(VERSION).tar
	rm -rf $(PACKAGE)-$(VERSION)

export:
	svn export $(SVNBASE)/tags/$(TAG) $(PACKAGE)-$(VERSION)

tag:
	@if svn list $(SVNBASE)/tags/$(TAG) &>/dev/null ; then \
	    echo "ERROR: tag \"$(TAG)\" probably already exists" ; \
	    exit 1 ; \
	else \
	    echo 'svn copy -m "Tag $(TAG)." . $(SVNBASE)/tags/$(TAG)' ; \
	    svn copy -m "Tag $(TAG)." . $(SVNBASE)/tags/$(TAG) ; \
	fi

AUTHORS: authors.xml authors.xsl
	xsltproc authors.xsl authors.xml | sort -u > $@

ChangeLog: $(FILES) authors.xml
	svn2cl --authors=authors.xml --group-by-day --strip-prefix=trunk

# Makefile ends here
