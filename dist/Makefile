
BUNDLER_URL="https://java.net/downloads/appbundler/appbundler-1.0.jar"
BLAST_URL=ftp://ftp.ncbi.nlm.nih.gov/blast/executables/blast+/LATEST
BLAST_MAC_URL="$(BLAST_URL)/ncbi-blast-2.3.0+-universal-macosx.tar.gz"
BLAST_LINUX_URL="$(BLAST_URL)/ncbi-blast-2.3.0+-x64-linux.tar.gz"
BLAST_WINDOWS_URL="$(BLAST_URL)/ncbi-blast-2.3.0+-x64-win64.tar.gz"

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

lib/shoes4:
	cd lib && git clone https://github.com/shoes/shoes4.git

../enveomics.rb:
	@echo Please restore all the contents from
	@echo https://github.com/lmrodriguezr/enveomics-git

#-- Packages
enveomics.jar: ../enveomics.rb bin lib/shoes4
	mkdir jar-pkg
	cp ../enveomics.rb jar-pkg/
	cp -r ../lib jar-pkg/
	cp -r ../img jar-pkg/
	cp -r bin jar-pkg/
	cd lib/shoes4 && bin/shoes-swt -p swt:jar ../../jar-pkg/enveomics.rb
	mv jar-pkg/pkg/enveomics.jar .
	rm -r jar-pkg

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

bin: bin/mac/blastp bin/linux/blastp bin/windows/blastp.exe
	
bin/mac/blastp: lib/ncbi-blast-macosx.tar.gz
	-mkdir -p bin/mac
	tar zxvf $<
	mv ncbi-blast-*/bin/* bin/mac/
	rm -r ncbi-blast-*

bin/linux/blastp: lib/ncbi-blast-linux.tar.gz
	-mkdir -p bin/linux
	tar zxvf $<
	mv ncbi-blast-*/bin/* bin/linux/
	rm -r ncbi-blast-*

bin/windows/blastp.exe: lib/ncbi-blast-windows.tar.gz
	-mkdir -p bin/windows
	tar zxvf $<
	mv ncbi-blast-*/bin/* bin/windows/
	rm -r ncbi-blast-*

lib/ncbi-blast-macosx.tar.gz:
	curl $(BLAST_MAC_URL) > $@
	
lib/ncbi-blast-linux.tar.gz:
	curl $(BLAST_LINUX_URL) > $@
	
lib/ncbi-blast-windows.tar.gz:
	curl $(BLAST_WINDOWS_URL) > $@

#-- Clean up
clean:
	rm -rf enveomics.*
	rm -rf lib/*
	rm -rf bin

