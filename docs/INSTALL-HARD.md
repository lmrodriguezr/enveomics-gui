Installing the enveomics GUI: the hard way
==========================================

1. Install [jruby](http://jruby.org/). You can probably find it in most of the
   many package managers available for your operative system, but that would be
   too easy. Heads up: you'll need the [JVM](https://www.java.com/en/download/)
   too.

2. Install the [shoes4](http://shoesrb.com/) libraries. The easiest way is
   installing the gem:
   ```bash
      $> jgem install shoes --pre
   ```
   Easy as pie. But then again, you might want a harder path, why else would you
   be reading this document? If so, then download the actual shoes4 base code
   from the [shoes github site](https://github.com/shoes/shoes4):
   ```bash
      $> git clone https://github.com/shoes/shoes4.git
      $> cd shoes4
      $> jgem install bundler
   ```
   The whole thing is ready, now lets put it in your jruby gem repo. To avoid
   problems with other `bundler` (from ruby or rails) I prefer to use the whole
   path. To find the location of the jruby gems' binaries and execute the proper
   `bundle`, use something like:
   ```bash
      $> jgem environment | grep "EXECUTABLE DIRECTORY"
        - EXECUTABLE DIRECTORY: /usr/local/Cellar/jruby/9.0.3.0/libexec/bin
      $> /usr/local/Cellar/jruby/9.0.3.0/libexec/bin/bundle install
   ```
   Just replace the actual path by whatever the output of the first line is.

3. Get the enveomics GUI and open the main script:
   ```bash
      $> git clone https://github.com/lmrodriguezr/enveomics-gui.git
      $> ./enveomics-gui/enveomics-gui
   ```
   Alternatively, open it with `shoes`:
   ```bash
      $> shoes ./enveomics-gui/enveomics-gui
   ```

