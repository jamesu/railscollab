require 'enum/enum_adapter'
require 'enum/mysql_adapter' if (ActiveRecord::ConnectionAdapters.const_defined? :MysqlAdapter)
#require 'enum/postgresql_adapter'
require 'enum/schema_statements'
require 'enum/quoting'
require 'enum/validations'
require 'enum/active_record_helper'
