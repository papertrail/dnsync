require 'optparse'
require 'configlet'
require 'pp'

require 'dnsync/dnsimple'
require 'dnsync/nsone'
require 'dnsync/zone_difference'

module Dnsync
  class Cli
    def initialize(argv)
      @args = argv.dup
    end
    
    def call
      Configlet.prefix = 'dnsync'
      read_env_from_file(File.expand_path("~/.dnsync.env"))
      read_env_from_file(File.expand_path("../../../.env", __FILE__))
      read_env_from_file('.env')

      opts = OptionParser.new do |opts|
        opts.on("--dnsimple-email=EMAIL", "DNSimple email address") do |v|
          Configlet[:dnsimple_email] = v
        end
        opts.on("--dnsimple-token=TOKEN", "DNSimple token") do |v|
          Configlet[:dnsimple_token] = v
        end
        opts.on("--nsone-token=TOKEN", "NSOne token") do |v|
          Configlet[:nsone_token] = v
        end
        opts.on("--domain=DOMAIN", "Domain to synchronize") do |v|
          Configlet[:domain] = v
        end
        opts.on("-h", "--help", "This help message") do
          puts opts
          exit(1)
        end
      end
      @args = opts.order(@args)
      
      case command = @args.shift
      when 'dump'
        dump
      when 'diff'
        diff
      else
        puts "Unknown command: #{command}"
        puts opts
        exit(1)
      end
      
      exit(0)
    end
    
    def dump
      case command = @args.shift
      when 'nsone'
        nsone = Nsone.new(Configlet[:nsone_token], Configlet[:domain])
        records = nsone.zone
      else
        dnsimple = Dnsimple.new(Configlet[:dnsimple_email], 
          Configlet[:dnsimple_token], Configlet[:domain])
        records = dnsimple.zone
      end
      
      pp records
    end
    
    def diff
      nsone = Nsone.new(Configlet[:nsone_token], Configlet[:domain])
      dnsimple = Dnsimple.new(Configlet[:dnsimple_email], 
        Configlet[:dnsimple_token], Configlet[:domain])
      
      diff = ZoneDifference.new(nsone.zone, dnsimple.zone,
        %w(NS SOA))

      puts " ---- added ---- "
      pp diff.added
      
      puts " ---- removed ---- "
      pp diff.removed
      
      puts " ---- changed ---- "
      pp diff.changed
    end
    
    private
    def unindent(string)
      indentation = string[/\A\s*/]
      string.strip.gsub(/^#{indentation}/, "") + "\n"
    end

    def read_env_from_file(filename)
      if File.exists?(filename)
        IO.read(filename).split(/\n+/).each do |line|
          ENV[$1] = $2 if line =~ /^([^#][^=]*)=(.+)$/
        end
      end
    end
  end
end