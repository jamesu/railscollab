class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true

  def self.define_index(&block)
    # TODO
  end
end
