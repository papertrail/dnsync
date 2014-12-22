module Dnsync
  class Answer
    include Comparable

    attr_reader :content, :priority
    
    def initialize(content, priority = nil)
      unless content.present?
        raise ArgumentError, 'content must be provided'
      end

      @content  = content
      @priority = priority

      freeze
    end
    
    def <=>(other)
      [ content, priority ] <=> [ other.content, other.priority ]
    end
    
    def hash
      [ content, priority ].hash
    end

    alias_method :eql?, :==
  end
end