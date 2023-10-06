require 'test_helper'

class ProjectFileTest < ActiveSupport::TestCase
  fixtures :all

  def test_file_tags
    do_test_tags(project_files(:owner_file))
  end
end
