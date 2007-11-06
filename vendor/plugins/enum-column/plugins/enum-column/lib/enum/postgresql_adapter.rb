
module ActiveRecord
  module ConnectionAdapters
    class PostgreSQLAdapter
      alias __add_column_options_enum! add_column_options!
      alias __native_database_types_enum native_database_types
      
      def native_database_types #:nodoc
        types = __native_database_types_enum
        types[:enum] = { :name => "character varying(32)" }
        types
      end

      def columns(table_name, name = nil)#:nodoc:
        column_definitions(table_name).collect do |name, type, default, notnull, consrc|
          values = nil
          if consrc and consrc =~ /ANY \(\(ARRAY(\[[^]]+\])/o and type == native_database_types[:enum][:name]
            values = eval $1.gsub(/::character varying/, '')
            type = 'enum'
          end
          
          # typmod now unused as limit, precision, scale all handled by superclass
          PostgreSQLColumnWithEnum.new(name, default_value(default),
                                       translate_field_type(type), notnull == "f",
                                       values)
        end
      end

      # Add constraints to the list of columns. This will only pick up check constraints.
      # We'll filter the constraint for the column type and ANY ((ARRAY[ type.
      def column_definitions(table_name)
        query <<-end_sql
          SELECT a.attname, format_type(a.atttypid, a.atttypmod), d.adsrc, a.attnotnull, c.consrc
            FROM pg_attribute a LEFT JOIN pg_attrdef d
              ON a.attrelid = d.adrelid AND a.attnum = d.adnum
              LEFT JOIN pg_constraint c ON a.attrelid = c.conrelid AND 
                c.contype = 'c' AND c.conkey[1] = a.attnum
            WHERE a.attrelid = '#{table_name}'::regclass
              AND a.attnum > 0 AND NOT a.attisdropped
            ORDER BY a.attnum
        end_sql
      end

      def add_column_options!(sql, options)
        unless sql =~ /\(32\)\('[^']+'/
          __add_column_options_enum!(sql, options)
        else
          sql.gsub!(/("[^"]+")([^3]+32\))(.+)/, '\1\2 CHECK(\1 in \3)')
          __add_column_options_enum!(sql, options)
        end
      end
    end
    
    class PostgreSQLColumnWithEnum < Column
      include ActiveRecordEnumerations::Column
      
      def initialize(name, default, sql_type = nil, null = true, values = nil)
        if values
          values = values.map { |v| v.intern }
          default = default.intern if default and !default.empty?
        end
        super(name, default, sql_type, null, values)
      end
    end
  end
end
