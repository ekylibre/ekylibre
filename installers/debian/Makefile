

all: build

build:
	cp -r ../../aquitan aquitan/usr/share
	find aquitan/usr/share/aquitan -name .svn -print0 | xargs -0 rm -fr
	dpkg --build aquitan
	rm -fr aquitan/usr/share/aquitan

