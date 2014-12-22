require 'active_support/core_ext/object/blank'

require 'dnsync/answer'
require 'dnsync/record_identifier'

module Dnsync
  class Record
    include Comparable

    attr_reader :identifier, :ttl, :answers

    def initialize(name, type, ttl, answers)
      unless ttl.present?
        raise ArgumentError, 'ttl must be provided'
      end

      unless answers.present?
        raise ArgumentError, 'at least one answer must be provided'
      end
      
      @identifier = RecordIdentifier.new(name, type)
      @ttl        = ttl
      @answers    = answers.sort

      freeze
    end
    
    def name
      @identifier.name
    end
    
    def type
      @identifier.type
    end
    
    def <=>(other)
      [ identifier, ttl, answers ] <=> [ other.identifier, other.ttl, other.answers ]
    end
    
    def hash
      [ identifier, ttl, answers ].hash
    end

    alias_method :eql?, :==
  end
end