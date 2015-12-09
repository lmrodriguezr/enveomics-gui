Enveomics GUI
=============

Graphical User Interface for [Enveomics][1].

What can I do with this?
========================
You can run any of the many scripts in [Enveomics][1] without ever opening
the terminal (you don't even need to know what the terminal is!). The scripts
in [Enveomics][1] are specialized tasks for genomics and metagenomics analyses.
Some popular examples include scripts to estimate average sequence identities
between genomes ([ani.rb][2] and [aai.rb][3]), alpha-diversity estimators from
profiles or OTU tables ([AlphaDiversity.pl][4] and [Chao1.pl][5]), and utilities
to split sequence files ([FastQ.split.pl][6] and [FastA.split.pl][7]). And there
is much much more!

Features
========
* Executes scripts easily, no programming experience necessary.
* Reports the exact command executed so you can easily log, reproduce, automate,
  and report analyses.
* Detached execution, so you can run multiple analyses at the same time.
* Self-updating, so you always get the latest version of our scripts.
* Zero configuration, just download and open.
* All the magic of [Shoes][8].

Show me, please!
================
My pleasure. Here's the home window:
![home](docs/img/Home.png)

Here, the complete index of tasks:
![all tasks](docs/img/AllTasks.png)

This is us preparing to calculate the Average Amino acid Identity (AAI) between
two genomes:
![aai form](docs/img/aai-form.png)

And the result window:
![aai result](docs/img/aai-result.png)

Install
=======
Prerequisites
-------------
You'll only need a [Java Virtual Machine][10] to open the GUI. However, you
might need other Software installed in your computer to execute certain scripts.
Notably, you'll need [Perl][11] to execute any of the tasks ending in `.pl` and
[Ruby][12] to execute any of the tasks ending in `.rb`. Also, the few tasks
ending in `.bash` will require a GNU Bash port in Windows machines, and some
tasks have additional requirements that are unlikely to ever work in Windows.
That said, we're trying to extend our support as wide as possible, so please
[report any issues][issues]. Finally, some tasks might depend on external
software like [BLAST][14].

Linux or BSD
------------
1. Download [enveomics.jar][jar].
2. Make sure you have [Java][10] or another implementation like [OpenJDK][15],
   and use it to open `enveomics.jar`. In most modern Linux distros you can
   simply right-click on the file and select to open with JVM or OpenJDK, or
   even just double-click the file. If it doesn't work please
   [let us know][issues], and execute this in the terminal:
   `java -jar enveomics.jar`, changing the path of `enveomics.jar` to wherever
   you downloaded it.

Mac OS X
--------
1. Download [enveomics.app][app] and unzip it.
2. Open it. You can also drag it to you `Applications` folder first if you want
   easy access at all times.

**Caveat:** It has come to our attention (#1) that the bundled app has low
resolution in OS X. We're working on solving this issue, but in the meantime you
can get around it by downloading [enveomics.jar][jar] instead, and running this
in the terminal: `java -jar -XstartOnFirstThread enveomics.jar`, changing the
path of `enveomics.jar` to wherever you downloaded it.

Windows
-------
Our current pre-release is yet to be tested in Windows. If you're not affraid of
bugs, just follow the same instructions above for Linux or BSD. And whatever
happens, please [let us know][issues].

Coming soon
===========
* Support for `enveomics.R`.
* Input multiple files for scripts supporting them.
* Easy installation, so terminal use is eliminated.

Credits
=======
The Enveomics GUI was developed on [Shoes 4][8] by Luis M. Rodriguez-R. For
additional information on the scripts collection, please refer to
[Enveomics][1]. Icons by [Yu Luck from the Noun Project][9].

License
=======
Enveomics GUI and the [Enveomics collection][1] are licensed under the terms of
[The Artistic License 2.0](LICENSE), except when otherwise noted.


[issues]: https://github.com/lmrodriguezr/enveomics-gui/issues
[jar]: https://github.com/lmrodriguezr/enveomics-gui/releases/download/v0.1.0-alpha2/enveomics.jar
[app]: https://github.com/lmrodriguezr/enveomics-gui/releases/download/v0.1.0-alpha2/enveomics.app.zip
[1]: https://github.com/lmrodriguezr/enveomics  "Enveomics collection"
[2]: http://enveomics.blogspot.com/2013/10/anirb.html
[3]: http://enveomics.blogspot.com/2013/10/aairb.html
[4]: http://enveomics.blogspot.com/2013/08/alphadiversitypl.html
[5]: http://enveomics.blogspot.com/2012/11/scripts-chao1pl.html
[6]: http://enveomics.blogspot.com/2012/11/fastasplitpl.html
[7]: http://enveomics.blogspot.com/2013/09/fastqsplitpl.html
[8]: https://github.com/shoes/shoes4 "Shoes 4"
[9]: https://thenounproject.com/yuluck
[10]: https://www.java.com/en/download/
[11]: https://www.perl.org/get.html
[12]: https://www.ruby-lang.org/en/documentation/installation/
[14]: https://blast.ncbi.nlm.nih.gov/Blast.cgi?PAGE_TYPE=BlastDocs&DOC_TYPE=Download
[15]: http://openjdk.java.net/
