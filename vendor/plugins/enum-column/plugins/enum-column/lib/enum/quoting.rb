module ActiveRecord
  module ConnectionAdapters # :nodoc:
    module Quoting
      alias __quote_enum quote

      # Quote a symbol as a normal string. This will support quoting of
      # enumerated values.
      def quote(value, column = nil)
        if !value.is_a? Symbol
          __quote_enum(value, column)
        else
          ActiveRecord::Base.send(:quote_bound_value, value.to_s)
        end
      end
    end
  end
end
