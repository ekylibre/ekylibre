

all: build

build:
	cp -r ../../ekylibre ekylibre/usr/share
	find ekylibre/usr/share/ekylibre -name .svn -print0 | xargs -0 rm -fr
	dpkg --build ekylibre
	rm -fr ekylibre/usr/share/ekylibre

