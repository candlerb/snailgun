Snailgun
========

This is a highly experimental, proof-of-concept piece of code which preloads
libraries into a Ruby process, and then forks that process whenever a new
command-line Ruby interpreter is required. The idea is to reduce the
slooooow startup of Ruby apps which require a large number of libraries.

In the case of Rails, separate processes are started for each of the
environments you are interested in (by default "test,development"), since
each may be configured differently.

Example 1: standalone
---------------------

    # WITHOUT SNAILGUN
    $ time ruby -rubygems -e 'require "active_support"' -e 'puts "".blank?'
    true

    real	0m2.123s
    user	0m1.424s
    sys 	0m0.168s

    # WITH SNAILGUN
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
    $ snailgun
    Use 'exit' to terminate snailgun

    # WITHOUT SNAILGUN
    $ time script/runner 'puts 1+2'
    3

    real	0m6.417s
    user	0m4.716s
    sys 	0m0.680s

    # WITH SNAILGUN
    $ time RAILS_ENV=development fruby script/runner 'puts 1+2'
    3

    real	0m0.169s
    user	0m0.040s
    sys 	0m0.008s

    $ time RAILS_ENV=test frake -T
    ....
    real	0m0.477s
    user	0m0.028s
    sys 	0m0.004s

    $ exit
    logout
    Snailgun ended
    $ 

To run your test suite, use `RAILS_ENV=test frake test`.

Note that for now, you need to set the appropriate environment before
starting fruby/frake (or pass `@tmp/sockets/snailgun/xxxx` on the command
line). This is so that the request is dispatched to the correct environment.

Snailgun wil take several seconds to be ready to process requests. Use
'snailgun -v' if you wish to be notified when it is ready.

By default, only 'development' and 'test' environments are loaded. You can
override this with `snailgun --rails test,development,production`

Bugs and limitations
--------------------
You need to specify the environment explicitly for each command, rather than
letting the script choose its default or select it from its command-line args.

    # Right
    RAILS_ENV=test frake test:units
    RAILS_ENV=development fruby script/server
    RAILS_ENV=production fruby script/server

    # Wrong
    frake test:units
    fruby script/server
    fruby script/server production

`fruby script/console` doesn't give any speedup, because script/console
uses exec to invoke irb. Needs a replacement script/console.

The environment is not currently passed across the socket to the ruby
process. This means it's not usable as a fast CGI replacement.

Only works with Linux/BSD systems, due to use of passing open file
descriptors across a socket. It could perhaps be made more portable by
proxying stdin/stdout/stderr across the socket instead.

In Rails, you need to beware that any changes to your `config/environment*`
will not be reflected until you stop and restart snailgun.

Licence
-------
This code is released under the same licence as Ruby itself.

Author
------
Brian Candler <B.Candler@pobox.com>
