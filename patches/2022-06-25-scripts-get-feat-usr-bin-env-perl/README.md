# get_feat.pl: use /usr/bin/env to find perl

This was my first Linux patch. It simply replaced `#!/usr/bin/perl` with `#!/usr/bin/env perl` to fix running the script on NixOS.

<https://lore.kernel.org/all/20220625211548.1200198-1-me@davidreaver.com/T/#u>
