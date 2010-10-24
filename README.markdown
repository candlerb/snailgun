Snailgun
========

Snailgun accelerates the startup of Ruby applications which require large
numbers of libraries.  It does this by preparing a Ruby process with your
chosen libraries preloaded, and then forking that process whenever a new
command-line Ruby interpreter is required.

Installation
------------

    sudo gem install snailgun

Or for the latest code, `git clone git://github.com/candlerb/snailgun.git`
and put the bin directory into your PATH.

Case 1: standalone
------------------

    # WITHOUT SNAILGUN
    $ time ruby -rubygems -e 'require "active_support"' -e 'puts "".blank?'
    true

    real	0m2.123s
    user	0m1.424s
    sys 	0m0.168s

    # WITH SNAILGUN
    $ snailgun -rubygems -ractive_support
    Snailgun starting on /home/brian/.snailgun/14781 - 'exit' to end
    $ time fruby -e 'puts "".blank?'
    true

    real	0m0.064s
    user	0m0.020s
    sys 	0m0.004s

    $ exit
    logout
    Snailgun ended
    $ 

Case 2: Rails app
-----------------

When using Rails or Merb, snailgun will start a process preloaded for the
`test` environment only unless told otherwise.

You need to edit `config/environments/test.rb` and set
`config.cache_classes = false`. This is so that your application classes
are loaded each time you run a test, rather than being preloaded into
the test environment.

Snailgun will take several seconds to be ready to process requests. Start
with `snailgun -v` if you wish to be notified when it is ready.

    $ rails testapp
    $ cd testapp
    $ vi config/environments/test.rb
    ... set config.cache_classes = false
    $ snailgun
    Now entering subshell. Use 'exit' to terminate snailgun

    $ time RAILS_ENV=test fruby script/runner 'puts 1+2'
    3

    real	0m0.169s
    user	0m0.040s
    sys 	0m0.008s

    # To run your test suite
    $ frake test       # or frake spec

Your preloaded process will remain around until you type `exit` to terminate
it.

Note that any attempt by `fruby` or `frake` to perform an action in an
environment other than 'test' will fail.  See below for how to run multiple
snailgun environments.

Merb support has been contributed (using MERB_ENV), but it is untested by
me.

Case 3: Rails with multiple environments
----------------------------------------

After reading the warnings below, you may choose to start multiple snailgun
processes each configured for a different environment, as follows:

    $ snailgun --rails test,development

This gives the potential for faster startup of rake tasks which involve
the development environment (such as migrations) and the console. The
utility `fconsole` is provided for this.

However, beware that frake and fruby need to decide which of the preloaded
environments to dispatch the command to.  The safest way is to force the
correct one explicitly:

    RAILS_ENV=test frake test:units
    RAILS_ENV=development fruby script/server
    RAILS_ENV=test fruby script/runner 'puts "".blank?'

If you do not specify the environment, then a simple heuristic is used:

* `fruby` always defaults to the 'development' environment.

* `frake` honours any `RAILS_ENV=xxx` setting on the command line. If
missing, `frake` defaults to the 'test' environment if no args are given or
if an arg containing the word 'test' or 'spec' is given; otherwise it falls
back to the 'development' environment.

WARNING: The decision as to which of the preloaded environments to use is
made *before* actually running the command.  If the wrong choice is made, it
can lead to problems.

In the worst case, you may have a 'test'-type task, but find that it is
wrongly dispatched to your 'development' environment - and possibly ends up
blowing away your development database.  This actually happened to me while
developing snailgun.  SO IF YOUR DEVELOPMENT DATABASE CONTAINS USEFUL DATA,
KEEP IT BACKED UP.

If you run test files individually, it is especially critical that you set
the correct environment. e.g.

    RAILS_ENV=test fruby -Ilib -Itest test/unit/some_test.rb

Case 4: Rails with cucumber
---------------------------

Cucumber creates its own Rails environment called "cucumber", so you can
setup snailgun like this:

    $ snailgun --rails test,cucumber

Then use `frake cucumber` to exercise the features. frake selects the
"cucumber" environment if run with "cucumber" as an argument.

NOTE: to make your model classes be loaded on each run you need to set
`config.cache_classes = false` in `config/environments/cucumber.rb`.
Cucumber will give a big warning saying that this is known to be a
problem with transactional fixtures. I don't use transactional fixtures
so this isn't a problem for me.

For a substantial performance boost, remove `:lib=>false` lines from
`config/environments/cucumber.rb` so that cucumber, webrat, nokogiri etc
are preloaded.

Smaller performance boosts can be had from further preloading.  For example,
cucumber makes use of some rspec libraries for diffing even if you're not
using rspec, so you can preload those. Add something like this to the end of
`config/environments/cucumber.rb`

    begin
      require 'spec/expectations'
      require 'spec/runner/differs/default'
    rescue LoadError
    end
    require 'test_help'
    require 'test/unit/testresult'
    require 'active_support/secure_random'
    require 'active_support/time_with_zone'

autotest
--------

There is some simple support for autotest (from the ZenTest package).
Just type `fautotest` instead of `autotest` after snailgun has been started.
This hasn't been tested for a while.

Bypassing rubygems
------------------

You can get noticeably faster startup if you don't use rubygems to invoke
the programs.  To do this, you can add the binary directory directly into
the front of your PATH, e.g. for Ubuntu

    PATH=/var/lib/gems/1.8/gems/snailgun-1.0.3/bin:$PATH

Alternatively, create a file called `fruby` somewhere early on in your PATH
(e.g. under `$HOME/bin`), like this:

    #!/usr/bin/env ruby
    load '/path/to/the/real/fruby'

Repeat for `frake` etc.

Other bugs and limitations
--------------------------
Only works with Linux/BSD systems, due to use of passing open file
descriptors across a socket.

Ctrl-C doesn't terminate frake processes.

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

Credits:

* Jan X <jan.h.xie@gmail.com>
* George Ogata <george.ogata@gmail.com>
* Niklas Hofer <niklas+dev@lanpartei.de>
* Thies C. Arntzen <thieso@gmail.com>
