class Author < ActiveRecord::Base
  has_many :edits
end

class Edit < ActiveRecord::Base
  belongs_to :author
  belongs_to :article
end

class Article < ActiveRecord::Base
  has_many :edits
  has_many :editors, :through => :edits, :source => :author
  belongs_to :author
end