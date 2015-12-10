
BUNDLER_URL="https://java.net/downloads/appbundler/appbundler-1.0.jar"

all: enveomics.jar enveomics.dmg enveomics.exe

#-- Dependencies
install-deps: /usr/local/bin/brew /Library/TeX/texbin/pdflatex
	brew install jruby ant pandoc
	jgem install shoes --pre

/usr/local/bin/brew:
	@if brew --version >/dev/null 2>/dev/null; then \
	   echo Install Homebrew http://brew.sh/ or \
	      Linuxbrew http://brew.sh/linuxbrew/; \
	fi

/Library/TeX/texbin/pdflatex:
	@if pdflatex --version >/dev/null 2>/dev/null; then \
	   echo Install MacTeX https://www.tug.org/mactex/ or \
	      LaTeX https://latex-project.org/ftp.html; \
	fi

#-- Packages
enveomics.jar:
	shoes-swt -p swt:jar ../enveomics.rb
	mv ../pkg/enveomics.jar .

enveomics.app: enveomics.jar lib/appbundler-1.0.jar
	ant enveomics

enveomics.dmg: enveomics.app lib/template.dmg lib/README.pdf lib/LICENSE.pdf
	hdiutil attach lib/template.dmg -noautoopen -quiet -mountpoint wc
	rm -rf wc/*
	rm -rf wc/.background
	ditto -rsrc lib/LICENSE.pdf wc/LICENSE.pdf
	ditto -rsrc lib/README.pdf wc/README.pdf
	ditto -rsrc enveomics.app wc/enveomics.app
	ditto -rsrc ../img/bg1-dmg.png wc/.background/bg1-dmg.png
	osascript dmg.as
	WC_D=`hdiutil info | grep wc | grep Apple_HFS | awk '{print $$1}'` && \
	   hdiutil detach $$WC_D -quiet -force
	hdiutil convert lib/template.dmg -quiet -format UDZO \
	   -imagekey zlib-level=9 -o "$@" || true

enveomics.exe:
	@echo Windows support not yet implemented
	touch enveomics.exe

#-- Files required for the different packaging functions:
lib:
	mkdir $@

lib/appbundler-1.0.jar: lib
	curl $(BUNDLER_URL) > $@

lib/template.dmg: lib
	mkdir template
	hdiutil create -fs HFSX -layout SPUD -size 150m $@ -srcfolder template \
	   -format UDRW -volname enveomics -quiet
	rmdir template

lib/%.pdf: ../%.md lib
	ln -s ../docs .
	pandoc -o $@ -f markdown_github $<
	rm docs

#-- Clean up
clean:
	rm -rf enveomics.*
	rm -rf lib/*.*

