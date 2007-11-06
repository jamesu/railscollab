
module ActiveRecord
  module ConnectionAdapters
    class MysqlAdapter
      alias __native_database_types_enum native_database_types
      
      def native_database_types #:nodoc
        types = __native_database_types_enum
        types[:enum] = { :name => "enum" }
        types
      end

      def columns(table_name, name = nil)#:nodoc:
        sql = "SHOW FIELDS FROM #{table_name}"
        columns = []
        execute(sql, name).each { |field| columns << MysqlColumnWithEnum.new(field[0], field[4], field[1], field[2] == "YES") }
        columns
      end
    end
    
    class MysqlColumnWithEnum < MysqlColumn
      include ActiveRecordEnumerations::Column
      
      def initialize(name, default, sql_type = nil, null = true)
        if sql_type =~ /^enum/i
          values = sql_type.sub(/^enum\('([^)]+)'\)/i, '\1').split("','").map { |v| v.intern }
          default = default.intern if default and !default.empty?
        end
        super(name, default, sql_type, null, values)
      end
    end
  end
end
