
class Enumeration < ActiveRecord::Base
  validates_columns :color, :severity, :string_field, :int_field
end

class BasicEnum < ActiveRecord::Base
  validates_columns :value
end

class BasicDefaultEnum < ActiveRecord::Base
  validates_columns :value
end

class NonnullEnum < ActiveRecord::Base
  validates_columns :value
end

class NonnullDefaultEnum < ActiveRecord::Base
  validates_columns :value
end
