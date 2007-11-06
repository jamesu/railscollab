
ActiveRecord::Schema.define do
  create_table :enumerations, :force => true do |t|
    t.column :severity, :enum, :limit => [:low, :medium, :high, :critical],
       :default => :medium
    t.column :color, :enum, :limit => [:red, :blue, :green, :yellow]
    t.column :string_field, :string, :limit => 8, :null => false
    t.column :int_field, :integer
  end


  create_table :basic_enums, :force => true  do |t|
    t.column :value, :enum, :limit => [:good, :working]
  end
  
  create_table :basic_default_enums, :force => true  do |t|
    t.column :value, :enum, :limit => [:good, :working],:default => :working
  end

  create_table :nonnull_enums, :force => true  do |t|
    t.column :value, :enum, :limit => [:good, :working],:null => false
  end

  create_table :nonnull_default_enums, :force => true  do |t|
    t.column :value, :enum, :limit => [:good, :working],:null => false,:default => :working
  end

end
