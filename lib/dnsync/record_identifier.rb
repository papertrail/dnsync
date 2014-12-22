require 'active_support/core_ext/object/blank'

module Dnsync
  class RecordIdentifier
    include Comparable

    attr_reader :name, :type

    def initialize(name, type)
      unless name.present?
        raise ArgumentError, 'name must be provided'
      end

      unless type.present?
        raise ArgumentError, 'type must be provided'
      end

      @name = name
      @type = type

      freeze
    end

    def <=>(other)
      [ name, type ] <=> [ other.name, other.type ]
    end

    def hash
      [ name, type ].hash
    end

    alias_method :eql?, :==
  end
end
