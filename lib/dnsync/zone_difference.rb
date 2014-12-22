module Dnsync
  class ZoneDifference
    def initialize(original, updated, ignored_types = nil)
      @original      = original
      @updated       = updated
      @ignored_types = ignored_types || []
    end
    
    def added
      @added ||= begin
        added_identifiers = @updated.record_identifiers - @original.record_identifiers
        added_identifiers = filter_types(added_identifiers)
        @updated.records_at(added_identifiers)
      end
    end
    
    def changed
      @changed ||= begin
        overlapping_identifiers = @updated.record_identifiers & @original.record_identifiers
        overlapping_identifiers = filter_types(overlapping_identifiers)
      
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
    end
    
    def removed
      @removed ||= begin
        removed_identifiers = @original.record_identifiers - @updated.record_identifiers
        removed_identifiers = filter_types(removed_identifiers)

        @original.records_at(removed_identifiers)
      end
    end

    def filter_types(identifiers)
      if @ignored_types.blank?
        return identifiers
      end

      identifiers.reject { |identifier| @ignored_types.include?(identifier.type) }
    end
  end
end
