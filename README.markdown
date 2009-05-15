Snailgun
========

This is a highly experimental, proof-of-concept piece of code which preloads
libraries into a Ruby process, and then forks that process whenever a new
Ruby interpreter is required. The idea is to reduce the slooooow startup of
Ruby apps which require a large number of libraries.

In the case of Rails, separate processes are started for each of the
environments you are interested in (by default "test,development"), since
each may be configured differently.

Example 1: standalone
---------------------

    $ time ruby -rubygems -e 'require "active_support"' -e 'puts "".blank?'
    true

    real	0m2.123s
    user	0m1.424s
    sys 	0m0.168s

    $ bin/snailgun -rubygems -ractive_support
    Snailgun starting on /home/brian/.snailgun/14781 - 'exit' to end
    $ time bin/fruby -e 'puts "".blank?'
    true

    real	0m0.064s
    user	0m0.020s
    sys 	0m0.004s

    $ exit
    logout
    Snailgun ended
    $ 

Example 2: inside a rails app
-----------------------------

    $ rails testapp
    $ cd testapp
    $ vi config/environments/test.rb
    ... set config.cache_classes = false
    $ ~/git/snailgun/bin/snailgun
    Use 'exit' to terminate snailgun
    Snailgun starting on /tmp/snailgun21717
    $ time script/runner 'puts 1+2'
    3

    real	0m6.417s
    user	0m4.716s
    sys 	0m0.680s

    $ time RAILS_ENV=development ~/git/snailgun/bin/fruby script/runner 'puts 1+2'
    3

    real	0m0.169s
    user	0m0.040s
    sys 	0m0.008s

    $ time RAILS_ENV=test ~/git/snailgun/bin/frake -T
    ....
    real	0m0.477s
    user	0m0.028s
    sys 	0m0.004s

    $ exit
    logout
    Snailgun ended
    $ 

Note that for now, you need to set the appropriate environment before
starting fruby/frake (or pass `@tmp/sockets/snailgun/xxxx` on the command
line). It should be possible to fix this by modifing script/* and
duplicating some of the logic from environment.rb in frake.

Bugs and limitations
--------------------
For some reason, `frake test:units` doesn't seem to run any tests :-(
Haven't worked out why yet.

`fruby script/console` stops the process when it reads from stdin. You need
to type `fg` to continue. Ditto for fruby reading from stdin. Haven't worked
out why yet.

The ruby child process doesn't have a supervisor parent, which means if
it dies using 'exit' we don't get the status code.

The environment is not currently passed across the socket to the ruby
process. This means it's not usable as a fast CGI replacement.

Only works with Linux/BSD systems, due to use of passing open file
descriptors across a socket. It could perhaps be made more portable by
proxying stdin/stdout/stderr across the socket instead.

Licence
-------
This code is released under the same licence as Ruby itself.

Author
------
Brian Candler <B.Candler@pobox.com>
