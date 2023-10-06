require 'test_helper'

class MilestoneTest < ActiveSupport::TestCase
  fixtures :all

  def test_milestone_tags
    do_test_tags(milestones(:owner_milestone))
  end
end
