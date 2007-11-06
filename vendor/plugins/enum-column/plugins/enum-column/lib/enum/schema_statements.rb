module ActiveRecord
  module ConnectionAdapters # :nodoc:
    module SchemaStatements
      alias __type_to_sql_enum type_to_sql

      # Add enumeration support for schema statement creation. This
      # will have to be adapted for every adapter if the type requires
      # anything by a list of allowed values. The overrides the standard
      # type_to_sql method and chains back to the default. This could 
      # be done on a per adapter basis, but is generalized here.
      #
      # will generate enum('a', 'b', 'c') for :limit => [:a, :b, :c]
      def type_to_sql(type, limit = nil, precision = nil, scale = nil) #:nodoc:
        if type == :enum
          native = native_database_types[type]
          column_type_sql = native[:name]
          
          column_type_sql << "(#{limit.map { |v| quote(v) }.join(',')})"
          column_type_sql          
        else
          # Edge rails fallback for Rails 1.1.6. We can remove the
          # rescue once everyone has upgraded to 1.2.
          begin
            __type_to_sql_enum(type, limit, precision, scale)
          rescue ArgumentError
            __type_to_sql_enum(type, limit)
          end
        end
      end
    end
  end
end
