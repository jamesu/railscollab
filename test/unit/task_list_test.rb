require 'test_helper'

class TaskListTest < ActiveSupport::TestCase
  fixtures :all

  def test_task_list_tags
    do_test_tags(task_lists(:owner_task_list))
  end
end
