module ActiveRecord
  class Errors
    
    # Error messages modified in lang file
    @@default_error_messages.update({
              :inclusion           => :error_message_inclusion.l,
              :exclusion           => :error_message_exclusion.l,
              :invalid             => :error_message_invalid.l,
              :confirmation        => :error_message_confirmation.l,
              :accepted            => :error_message_accepted.l,
              :empty               => :error_message_empty.l,
              :blank               => :error_message_blank.l,
              :too_long            => :error_message_too_long.l,
              :too_short           => :error_message_too_short.l,
              :wrong_length        => :error_message_wrong_length.l,
              :taken               => :error_message_taken.l,
              :not_a_number        => :error_message_not_a_number.l,
            })
    
    # Reloads the localization
    def self.relocalize
      @@default_error_messages.update({
                :inclusion           => :error_message_inclusion.l,
                :exclusion           => :error_message_exclusion.l,
                :invalid             => :error_message_invalid.l,
                :confirmation        => :error_message_confirmation.l,
                :accepted            => :error_message_accepted.l,
                :empty               => :error_message_empty.l,
                :blank               => :error_message_blank.l,
                :too_long            => :error_message_too_long.l,
                :too_short           => :error_message_too_short.l,
                :wrong_length        => :error_message_wrong_length.l,
                :taken               => :error_message_taken.l,
                :not_a_number        => :error_message_not_a_number.l,
              })
    end
    
    # # Handle model error localization
    # def add(attribute, msg = @@default_error_messages[:invalid])
    #        @errors[attribute.l] = [] if @errors[attribute.to_s].nil?
    #        @errors[attribute.l] << msg
    # end
    
  end
end