require 'test_helper'

class TagTest < ActiveSupport::TestCase
  fixtures :all

  def test_find_objects
    ms = milestones(:owner_milestone)
    ms.tags = "test1,test2,test3"
    ms.save!

    mes = messages(:owner_welcome_message)
    mes.tags = "test1,test3"
    mes.save!

    assert_equal 2, Tag.find_objects('test1', projects(:owner_project), true).count
    assert_equal 1, Tag.find_objects('test2', projects(:owner_project), true).count
    assert_equal 2, Tag.find_objects('test3', projects(:owner_project), true).count
    assert_equal 0, Tag.find_objects('test1', projects(:client_project), true).count
    assert_equal 0, Tag.find_objects('test2', projects(:client_project), true).count
    assert_equal 0, Tag.find_objects('test3', projects(:client_project), true).count

    assert_equal "Message#{mes.id},Milestone#{ms.id}", Tag.find_objects('test1', projects(:owner_project), true).map{|o| "#{o.class}#{o.id}"}.sort.join(',')
  end

  def test_objects
    ms = milestones(:owner_milestone)
    ms.tags = "test1,test2,test3"
    ms.save!

    mes = messages(:owner_welcome_message)
    mes.tags = "test1,test3"
    mes.save!

    assert_equal 2, Tag.where(project: projects(:owner_project), tag: 'test1').first.objects.count
    assert_equal 1, Tag.where(project: projects(:owner_project), tag: 'test2').first.objects.count
    assert_equal 2, Tag.where(project: projects(:owner_project), tag: 'test3').first.objects.count
    assert_nil Tag.where(project: projects(:client_project), tag: 'test1').first
    assert_nil Tag.where(project: projects(:client_project), tag: 'test2').first
    assert_nil Tag.where(project: projects(:client_project), tag: 'test3').first

    assert_equal "Message#{mes.id},Milestone#{ms.id}", Tag.where(tag: 'test1').first.objects.map{|o| "#{o.class}#{o.id}"}.sort.join(',')
  end

  def test_clear
    ms = milestones(:owner_milestone)
    ms.tags = "test1,test2,test3"
    ms.save!

    mes = messages(:owner_welcome_message)
    mes.tags = "test1,test3"
    mes.save!

    assert_equal 2, Tag.find_objects('test1', projects(:owner_project), true).count
    assert_equal 1, Tag.find_objects('test2', projects(:owner_project), true).count
    assert_equal 2, Tag.find_objects('test3', projects(:owner_project), true).count

    Tag.clear_by_object(ms)

    assert_equal 1, Tag.find_objects('test1', projects(:owner_project), true).count
    assert_equal 0, Tag.find_objects('test2', projects(:owner_project), true).count
    assert_equal 1, Tag.find_objects('test3', projects(:owner_project), true).count
  end

  def test_set_to_object
    ms = milestones(:owner_milestone)
    Tag.set_to_object(ms, %w{a b c})

    assert_equal 1, Tag.find_objects('a', projects(:owner_project), true).count
    assert_equal 1, Tag.find_objects('b', projects(:owner_project), true).count
    assert_equal 1, Tag.find_objects('c', projects(:owner_project), true).count

    Tag.set_to_object(ms, [])

    assert_equal 0, Tag.find_objects('a', projects(:owner_project), true).count
    assert_equal 0, Tag.find_objects('b', projects(:owner_project), true).count
    assert_equal 0, Tag.find_objects('c', projects(:owner_project), true).count
  end

  def test_list_by_object
    ms = milestones(:owner_milestone)

    assert_equal [], Tag.list_by_object(ms).sort

    ms.tags = "test4,test5"
    ms.save!

    assert_equal %w{test4 test5}, Tag.list_by_object(ms).sort
  end

  def test_list_by_project
    ms = milestones(:owner_milestone)

    assert_equal [], Tag.list_by_project(ms.project, true).sort

    ms.tags = "test4,test5"
    ms.save!

    assert_equal %w{test4 test5}, Tag.list_by_object(ms).sort
  end

  def test_count_by
    ms = milestones(:owner_milestone)

    assert_equal [], Tag.list_by_project(ms.project, true).sort

    ms.tags = "test4,test5"
    ms.save!

    assert_equal 0, Tag.count_by('test3', ms.project, true)
    assert_equal 1, Tag.count_by('test4', ms.project, true)
    assert_equal 1, Tag.count_by('test5', ms.project, true)

    Tag.clear_by_object(ms)

    assert_equal 0, Tag.count_by('test3', ms.project, true)
    assert_equal 0, Tag.count_by('test4', ms.project, true)
    assert_equal 0, Tag.count_by('test5', ms.project, true)
  end


end
