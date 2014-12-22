require 'dnsync/zone_updater'
require 'atomic'

module Dnsync
  class RecurringZoneUpdater
    def initialize(source, destination, frequency)
      @source      = source
      @destination = destination
      @frequency   = frequency
      
      @thread  = Atomic.new(nil)
      @running = Atomic.new(false)
    end

    def start
      if (thread = @thread.value) && thread.alive?
        return self
      end

      @running.value = true

      @thread.value = Thread.new do
        Thread.current.abort_on_exception = true

        run
      end
    end

    def stop
      @running.value = false
      self
    end

    def join
      if thread = @thread.value
        thread.join
      end

      self
    end

    def run
      active_zone = nil

      while @running.value
        begin
          source_zone = nil

          Scrolls.log(:from => :recurring_zone_updater, :zone => @source.domain, :for => :source) do
            source_zone = @source.zone
          end

          if !active_zone
            Scrolls.log(:from => :recurring_zone_updater, :zone => @source.domain, :for => :destination) do
              active_zone = @destination.zone
            end
          end

          diff = ZoneDifference.new(active_zone, source_zone, %w(NS SOA))

          Scrolls.log(:from => :recurring_zone_updater, :zone => @source.domain,
            :action => :updating, :adding => diff.added.length,
            :updating => diff.changed.length, :removing => diff.removed.length) do

              updater = ZoneUpdater.new(diff, @destination)
              updater.call
          end

          active_zone = source_zone
        rescue => e
          Scrolls.log_exception({ :from => :recurring_zone_updater, :zone => @source.domain }, e)
        end

        if @running.value
          sleep_until_next_deadline
        end
      end
    end

    def sleep_until_next_deadline
      if !@deadline
        @deadline = Time.now.to_f
      end

      @deadline = @deadline + @frequency

      sleep_duration = @deadline - Time.now.to_f

      if sleep_duration <= 0
        Scrolls.log(:from => :recurring_zone_updater, :for => :missed_deadline, :by => sleep_duration)
        @deadline = Time.now.to_f
      else
        sleep sleep_duration
      end
    end
  end
end