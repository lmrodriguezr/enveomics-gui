Enveomics GUI
=============

Graphical User Interface for [Enveomics][1].

What can I do with this?
------------------------
You can run any of the many scripts in [Enveomics][1] without ever opening
the terminal (you don't even need to know what the terminal is!). The scripts
in [Enveomics][1] are specialized tasks for genomics and metagenomics analyses.
Some popular examples include scripts to estimate average sequence identities
between genomes ([ani.rb][2] and [aai.rb][3]), alpha-diversity estimators from
profiles or OTU tables ([AlphaDiversity.pl][4] and [Chao1.pl][5]), and utilities
to split sequence files ([FastQ.split.pl][6] and [FastA.split.pl][7]). And there
is much much more!

Features
--------
* Executes scripts easily, no programming or even terminal use experience
  needed.
* Reports the exact command executed, so you can reproduce, automate, and report
  analyses easily.
* Detached execution, so you can run multiple analyses at the same time.
* Self-updating, so you always get the latest version of our scripts.
* Zero configuration, just download and open.
* All the magic of [Shoes][8].

Show me, please!
----------------
My pleasure. Here's the home window:
![home](docs/img/Home.png)

Here, the complete index of tasks:
![all tasks](docs/img/AllTasks.png)

This is us preparing to calculate the Average Amino acid Identity (AAI) between
two genomes:
![aai form](docs/img/aai-form.png)

And the result window:
![aai result](docs/img/aai-result.png)

Coming soon
-----------
* Support for `enveomics.R`.
* Input multiple files for scripts supporting them.

Credits
-------
The Enveomics GUI was developed on [Shoes 4][8] by Luis M. Rodriguez-R. For
additional information on the scripts collection, please refer to
[Enveomics][1]. Icons by [Yu Luck from the Noun Project][9].

License
-------
Enveomics GUI and the [Enveomics collection][1] are licensed under the terms of
[The Artistic License 2.0](LICENSE), except when otherwise noted.


[1]: https://github.com/lmrodriguezr/enveomics  "Enveomics collection"
[2]: http://enveomics.blogspot.com/2013/10/anirb.html
[3]: http://enveomics.blogspot.com/2013/10/aairb.html
[4]: http://enveomics.blogspot.com/2013/08/alphadiversitypl.html
[5]: http://enveomics.blogspot.com/2012/11/scripts-chao1pl.html
[6]: http://enveomics.blogspot.com/2012/11/fastasplitpl.html
[7]: http://enveomics.blogspot.com/2013/09/fastqsplitpl.html
[8]: https://github.com/shoes/shoes4 "Shoes 4"
[9]: https://thenounproject.com/yuluck
