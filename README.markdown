Snailgun
========

Snailgun accelerates the startup of Ruby applications which require large
numbers of libraries. It does this by preparing a Ruby process with the
libraries preloaded, and then forking that process whenever a new
command-line Ruby interpreter is required.

When using Rails or Merb, separate processes are started for each of the
environments you are interested in (by default `test,development`), since
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
    $ time fruby script/runner 'puts 1+2'
    3

    real	0m0.169s
    user	0m0.040s
    sys 	0m0.008s

    $ time frake -T
    ....
    real	0m0.477s
    user	0m0.028s
    sys 	0m0.004s

To run your test suite, use `frake test`. Remember to `exit` to terminate
your preloaded processes.

Snailgun will take several seconds to be ready to process requests. Start
using `snailgun -v` if you wish to be notified when it is ready.

By default, only 'development' and 'test' environments are loaded. You can
override this, e.g.

    snailgun --rails test,development,production

Choice of environment
---------------------
With Rails/Merb, frake and fruby need to decide which of the preloaded
environments to dispatch the command to. The safest way is to force the
correct one explicitly:

    RAILS_ENV=test frake test:units
    RAILS_ENV=development fruby script/server
    RAILS_ENV=production fruby script/server

Otherwise, a simple default heuristic is used. `fruby` always defaults to
the 'development' environment. `frake` honours any `RAILS_ENV=xxx` setting
on the command line. Otherwise, `frake` defaults to the 'test' environment
if no args are given or if an arg containing the word 'test' is given, or
else to the 'development' environment.

Bugs and limitations
--------------------
Only works with Linux/BSD systems, due to use of passing open file
descriptors across a socket.

Because fruby has to choose the environment to dispatch the request to
before it is run, the default choice may be wrong and you may have to
override it using an environment variable. IT'S POSSIBLE YOU COULD LOSE
DATA FROM YOUR DEVELOPMENT DATABASE IF YOU RUN A 'TEST'-TYPE TASK BUT
SNAILGUN APPLIES IT TO THE DEFAULT 'DEVELOPMENT' ENVIRONMENT. If your
development database contains useful data, keep it backed up.

    # Wrong
    fruby script/server production

    # Right
    RAILS_ENV=production fruby script/server

`fruby script/console` doesn't give any speedup, because script/console uses
exec to invoke irb.  Use the supplied `fconsole` instead.

The environment is not currently passed across the socket to the ruby
process. This means it's not usable as a fast CGI replacement.

In Rails, you need to beware that any changes to your `config/environment*`
will not be reflected until you stop and restart snailgun.

Licence
-------
This code is released under the same licence as Ruby itself.

Author
------
Brian Candler <B.Candler@pobox.com>
