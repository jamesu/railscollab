
# This module provides all the column helper methods to deal with the
# values and adds the common type management code for the adapters.
module ActiveRecordEnumerations
  module Column
    # Add the values accessor to the column class.
    def self.included(klass)
      klass.module_eval <<-EOE
        attr_reader :values
      EOE
    end

    # Add the type to the native database types. This will most
    # likely need to be modified in the adapter as well.
    def native_database_types
      types = super
      types[:enum] = { :name => "enum" }
      types
    end

    # The new constructor with a values argument.
    def initialize(name, default, sql_type = nil, null = true, values = nil)
      super(name, default, sql_type, null)
      @values = values
      @limit = values if type == :enum
    end

    # The class for enum is Symbol.
    def klass
      if type == :enum
        Symbol
      else
        super
      end
    end

    # Convert to a symbol.
    def type_cast(value)
      return nil if value.nil?
      if type == :enum
        ActiveRecordEnumerations::Column.value_to_symbol(value)
      else
        super
      end
    end

    # Code to convert to a symbol.
    def type_cast_code(var_name)
      if type == :enum
        "ActiveRecordEnumerations::Column.value_to_symbol(#{var_name})"
      else
        super
      end
    end

    # The enum simple type.
    def simplified_type(field_type)
      if field_type =~ /enum/i
        :enum
      else
        super
      end
    end

    # Safely convert the value to a symbol. 
    def self.value_to_symbol(value)
      case value
      when Symbol
        value
      when String
        value.empty? ? nil : value.intern
      else
        nil
      end
    end
  end
end
