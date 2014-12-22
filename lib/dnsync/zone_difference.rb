module Dnsync
  class ZoneDifference
    def initialize(original, updated)
      @original = original
      @updated  = updated
    end
    
    def added
      added_identifiers = @updated.record_identifiers - @original.record_identifiers
      @updated.records_at(added_identifiers)
    end
    
    def changed
      overlapping_identifiers = @updated.record_identifiers & @original.record_identifiers
      
      overlapping_identifiers.map do |identifier|
        original_record = @original[identifier]
        updated_record  = @updated[identifier]
        
        if original_record != updated_record
          updated_record
        else
          nil
        end
      end.compact
    end
    
    def removed
      removed_identifiers = @original.record_identifiers - @updated.record_identifiers
      @original.records_at(removed_identifiers)
    end
  end
end
