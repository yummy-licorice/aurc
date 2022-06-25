PREFIX = /usr/local/

all:
	@nimble build -d=ssl

install:
	@cp aurc $(DESTDIR)$(PREFIX)/bin/aurc


uninstall:
	@rm -rf $(DESTDIR)$(PREFIX)bin/aurc

