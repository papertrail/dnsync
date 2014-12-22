require 'set'
require 'dnsync/record'


module Dnsync
  class Zone
    attr_reader :name

    def initialize(name, records)
      @name = name

      @records_by_identifier = {}
      records.each do |record|
        @records_by_identifier[record.identifier] = record
      end

      freeze
    end
    
    def [](identifier)
      @records_by_identifier[identifier]
    end
    
    def records_at(*identifiers)
      @records_by_identifier.values_at(*identifiers.flatten)
    end
    
    def records
      @records_by_identifier.values
    end
    
    def record_identifiers
      @records_by_identifier.keys
    end
  end
end