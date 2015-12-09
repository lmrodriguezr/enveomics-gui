
all: enveomics.jar enveomics.app enveomics.exe

install-deps: /usr/local/bin/brew
	brew install jruby ant
	jgem install shoes --pre

/usr/local/bin/brew:
	@if brew --version >/dev/null 2>/dev/null; then \
	   echo Install Homebrew http://brew.sh/ or \
	      Linuxbrew http://brew.sh/linuxbrew/; \
	fi

enveomics.jar:
	shoes-swt -p swt:jar ../enveomics.rb
	mv ../pkg/enveomics.jar .

enveomics.app: enveomics.jar lib
	cd lib && $(MAKE)
	ant enveomics

enveomics.exe:
	@echo Windows support not yet implemented
	touch enveomics.exe

clean:
	rm -Rf enveomics.jar enveomics.app enveomics.exe
	cd lib && $(MAKE) clean

