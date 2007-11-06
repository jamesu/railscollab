module ActiveRecord
  module Validations
    module ClassMethods
      # Automatically validates the column against the schema definition
      # for nullability, format, and enumerations. Handles integers, floats,
      # enumerations, and string limits.
      #
      # Usage: validates_columns :severity, :name
      def validates_columns(*column_names)
        cols = columns_hash
        column_names.each do |name|
          col = cols[name.to_s]
          raise ArgumentError, "Cannot find column #{name}" unless col
          
          # test for nullability
          validates_presence_of(name) if !col.null
          
          # Test various known types.
          case col.type
          when :enum
            validates_inclusion_of name, :in => col.values, :allow_nil => true
            
          when :integer, :float
            validates_numericality_of name, :allow_nil => true
            
          when :string
            if col.limit
              validates_length_of name, :maximum => col.limit, :allow_nil => true
            end
          end
        end
      end
    end
  end
end
