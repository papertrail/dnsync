module Dnsync
  class ZoneUpdater
    def initialize(difference, target)
      @difference = difference
      @target     = target
    end

    def call
      @difference.added.each do |record|
        @target.create_record(record)
      end

      @difference.changed.each do |record|
        @target.update_record(record)
      end

      @difference.removed.each do |record|
        @target.remove_record(record)
      end
    end
  end
end