require 'optparse'
require 'configlet'
require 'pp'
require 'scrolls'

require 'dnsync/dnsimple'
require 'dnsync/nsone'
require 'dnsync/zone_difference'
require 'dnsync/zone_updater'
require 'dnsync/recurring_zone_updater'
require 'dnsync/http_status'

module Dnsync
  class Cli
    attr_reader :program_name

    def initialize(argv)
      @args         = argv.dup
      @program_name = File.basename($0)
    end
    
    def call
      Configlet.prefix = 'dnsync'
      Configlet.munge(:noop) { |v| v == "true" }
      Configlet.munge(:monitor_frequency) { |v| v.present? ? v.to_i : v }

      Scrolls.single_line_exceptions = true

      read_env_from_file(File.expand_path("~/.dnsync.env"))
      read_env_from_file(File.expand_path("../../../.env", __FILE__))
      read_env_from_file('.env')

      opts = OptionParser.new do |opts|
        opts.banner = "usage: #{program_name} [options] <command> [<args>]"

        opts.separator ""
        opts.separator commands_help

        opts.separator ""
        opts.separator "Options:"

        opts.on("--dnsimple-email=EMAIL", "DNSimple email address") do |v|
          Configlet[:dnsimple_email] = v
        end
        opts.on("--dnsimple-token=TOKEN", "DNSimple token") do |v|
          Configlet[:dnsimple_token] = v
        end
        opts.on("--nsone-token=TOKEN", "NSONE token") do |v|
          Configlet[:nsone_token] = v
        end
        opts.on("--domain=DOMAIN", "Domain to synchronize") do |v|
          Configlet[:domain] = v
        end
        opts.on("--monitor-frequency=FREQUENCY", "Frequency to check DNSimple for updates") do |v|
          Configlet[:monitor_frequency] = v
        end
        opts.on("--status-port=PORT", "Port to run status HTTP server on") do |v|
          Configlet[:status_port] = v
        end
        opts.on("--status-grace-period=PERIOD", "Number of failed updates before reporting an error") do |v|
          Configlet[:status_grace_period] = v
        end
        opts.on("--noop", "Don't do any write operations") do |v|
          Configlet[:noop] = v.to_s
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
      when 'sync'
        sync
      when 'monitor'
        monitor
      else
        puts "#{program_name}: '#{command}' is not a command. see '#{program_name} --help'."
        exit(1)
      end
      
      exit(0)
    end
    
    def commands_help
      unindent(<<-EOF)
        The available commands are:
             sync         Perform a one-time synchronization from DNSimple to NSONE
             monitor      Perform continual synchronization from DNSimple to NSONE

      EOF
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
    
    def sync
      nsone = Nsone.new(Configlet[:nsone_token], Configlet[:domain])
      dnsimple = Dnsimple.new(Configlet[:dnsimple_email],
        Configlet[:dnsimple_token], Configlet[:domain])

      nsone_zone, dnsimple_zone = nil

      Scrolls.log(:zone => Configlet[:domain], :from => :nsone) do
        nsone_zone = nsone.zone
      end

      Scrolls.log(:zone => Configlet[:domain], :from => :dnsimple) do
        dnsimple_zone = dnsimple.zone
      end

      diff = ZoneDifference.new(nsone_zone, dnsimple_zone,
        %w(NS SOA))

      if Configlet[:noop]
        puts "Would be: Adding: #{diff.added.length} Updating: #{diff.changed.length} Removing: #{diff.removed.length}"
      else
        updater = ZoneUpdater.new(diff, nsone)

        Scrolls.log(:zone => Configlet[:domain], :action => :updating, :to => :nsone,
          :adding => diff.added.length, :updating => diff.changed.length,
          :removing => diff.removed.length) do
          updater.call
        end
      end
    end

    def monitor
      nsone = Nsone.new(Configlet[:nsone_token], Configlet[:domain])
      dnsimple = Dnsimple.new(Configlet[:dnsimple_email],
        Configlet[:dnsimple_token], Configlet[:domain])

      updater = RecurringZoneUpdater.new(dnsimple, nsone,
        Configlet[:monitor_frequency] || 10,
        Configlet[:status_grace_period] || 5)
      updater.start

      if status_port = Configlet[:status_port]
        puts "Starting status server on #{status_port}"
        status = HttpStatus.new(status_port, updater)
        status.start
      end

      rd, wr = IO.pipe
      Thread.new do
        # Wait for a signal
        rd.read(1)
        updater.stop

        if status
          status.stop
        end
      end

      %w(QUIT HUP INT TERM).each do |sig|
        Signal.trap(sig) { wr.write('x') }
      end

      updater.join
      if status
        status.join
      end
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