# Copyright (C) Brian Candler 2009. Released under the Ruby licence.

require 'socket'
require 'optparse'

module Snailgun
  class Server
    attr_accessor :sockname

    def initialize(sockname = nil)
      @sockname = sockname || "/tmp/snailgun#{$$}"
      yield self if block_given?
    end

    def run
      File.delete(@sockname) rescue nil
      server = UNIXServer.open(@sockname)
      while client = server.accept
        fork do
          begin
            STDIN.reopen(client.recv_io)
            STDOUT.reopen(client.recv_io)
            STDERR.reopen(client.recv_io)
            nbytes = client.read(4).unpack("N").first
            args, cwd = Marshal.load(client.read(nbytes))
            Dir.chdir(cwd)
            thc = Thread.current
            Thread.new { client.read(1); thc.kill }
            start_ruby(args)
            client.write "\000"
          rescue Exception => e
            STDERR.puts "#{e}\n\t#{e.backtrace.join("\n\t")}"
            client.write "\001"
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
      end.parse!(args)

      ARGV.replace(args)
      if !e.empty?
        e.each { |expr| eval(expr, TOPLEVEL_BINDING) }
      elsif ARGV.empty?
        eval(STDIN.read, TOPLEVEL_BINDING)
      else
        cmd = ARGV.shift
        load(cmd)
      end
    end
    
    def self.shell
      system("bash -l")  # TODO: configurable
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
