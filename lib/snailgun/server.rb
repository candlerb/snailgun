# Copyright (C) Brian Candler 2009. Released under the Ruby licence.

# Our at_exit handler must be called *last*
at_exit { $SNAILGUN_EXIT.call if $SNAILGUN_EXIT }

require 'socket'
require 'optparse'

module Snailgun
  class Server
    attr_accessor :sockname

    def initialize(sockname = nil)
      @sockname = sockname || "/tmp/snailgun#{$$}"
      File.delete(@sockname) rescue nil
      @socket = UNIXServer.open(@sockname)
      yield self if block_given?
    end

    def run
      while client = @socket.accept
        fork do
          begin
            STDIN.reopen(client.recv_io)
            STDOUT.reopen(client.recv_io)
            STDERR.reopen(client.recv_io)
            nbytes = client.read(4).unpack("N").first
            args, cwd, pgid = Marshal.load(client.read(nbytes))
            Dir.chdir(cwd)
            begin
              Process.setpgid(0, pgid)
            rescue Errno::EPERM
            end
            exit_status = 0
            $SNAILGUN_EXIT = lambda {
              begin
                client.write [exit_status].pack("C")
              rescue Errno::EPIPE
              end
            }
            #This doesn't work in 1.8.6:
            #Thread.new { client.read(1); Thread.main.raise Interrupt }
            Thread.new { client.read(1); exit 1 }
            start_ruby(args)
          rescue SystemExit => e
            exit_status = e.status
            raise  # for the benefit of Test::Unit
          rescue Exception => e
            STDERR.puts "#{e}\n\t#{e.backtrace.join("\n\t")}"
            exit 1
          end
        end
        client.close
      end
    ensure
      File.delete(@sockname) rescue nil
    end

    # Process the received ruby command line. (TODO: implement more options)
    def start_ruby(args)
      e = []
      OptionParser.new do |opts|
        opts.on("-e EXPR") do |v|
          e << v
        end
        opts.on("-I DIR") do |v|
          $:.unshift v
        end
        opts.on("-r LIB") do |v|
          require v
        end
      end.order!(args)

      ARGV.replace(args)
      if !e.empty?
        $0 = '-e'
        e.each { |expr| eval(expr, TOPLEVEL_BINDING) }
      elsif ARGV.empty?
        $0 = '-'
        eval(STDIN.read, TOPLEVEL_BINDING)
      else
        cmd = ARGV.shift
        $0 = cmd
        load(cmd)
      end
    end
    
    def self.shell
      system("#{ENV['shell'] || 'bash'} -l")   # TODO: configurable
    end

    # Interactive mode (start a subshell with SNAILGUN_SOCK set up,
    # and terminate the snailgun server when the subshell exits)
    def interactive!
      ENV['SNAILGUN_SOCK'] = @sockname
      pid = Process.fork {
        STDERR.puts "Snailgun starting on #{sockname} - 'exit' to end"
        run
      }
      self.class.shell
      Process.kill('TERM',pid)
      # TODO: wait a few secs for it to die, 'KILL' if required
      STDERR.puts "Snailgun ended"
    end
  end
end
