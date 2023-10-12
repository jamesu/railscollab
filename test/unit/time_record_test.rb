require 'test_helper'

class TimeRecordTest < ActiveSupport::TestCase
  fixtures :all

  def test_time_tags
    tr = projects(:owner_project).time_records.new(name: "Time", created_by: User.first)
    tr.save!

    do_test_tags(project_files(:owner_file))

    tr.destroy
  end

  def test_validations
  end
end
