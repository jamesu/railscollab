require File.dirname(__FILE__) + '/test_helper'
require 'fixtures/enumeration'

class EnumerationsTest < Test::Unit::TestCase
  class EnumController < ActionController::Base
    def test1
      @test = Enumeration.new
      render :inline => "<%= input('test', 'severity')%>"
    end

    def test2
      @test = Enumeration.new
      render :inline => "<%= enum_radio('test', 'severity')%>"
    end
  end

  def setup
    Enumeration.connection.execute 'DELETE FROM enumerations'
  end
  
  def test_column_values
    columns = Enumeration.columns_hash
    color_column = columns['color']
    assert color_column
    assert_equal [:red, :blue, :green, :yellow], color_column.values

    severity_column = columns['severity']
    assert severity_column
    assert_equal [:low, :medium, :high, :critical], severity_column.values
    assert_equal :medium, severity_column.default
  end

  def test_insert_enum
    row = Enumeration.new
    row.color = :blue
    row.string_field = 'test'
    assert_equal :medium, row.severity
    assert row.save

    db_row = Enumeration.find(row.id)
    assert db_row
    assert :blue, row.color
    assert :medium, row.severity
  end

  # Uses the automatic validates_columns to create automatic validation rules
  # for columns based on the schema information.
  def test_bad_value
    row = Enumeration.new
    row.color = :violet
    row.string_field = 'test'
    assert !row.save
    
    assert row.errors
    assert_equal 'is not included in the list', row.errors['color']
  end

  def test_other_types
    row = Enumeration.new
    row.string_field = 'a' * 10
    assert !row.save
    assert_equal 'is too long (maximum is 8 characters)', row.errors['string_field']

    row = Enumeration.new
    assert !row.save
    assert_equal 'can\'t be blank', row.errors['string_field']

    row = Enumeration.new
    row.string_field = 'test'
    row.int_field = 'aaaa'
    assert !row.save
    assert_equal 'is not a number', row.errors['int_field']

    row = Enumeration.new
    row.string_field = 'test'
    row.int_field = '500'
    assert row.save
  end

  def test_view_helper
    request  = ActionController::TestRequest.new
    response = ActionController::TestResponse.new
    request.action = 'test1'
    body = EnumController.process(request, response).body
    assert_equal '<select id="test_severity" name="test[severity]"><option value="low">low</option><option value="medium" selected="selected">medium</option><option value="high">high</option><option value="critical">critical</option></select>', body
  end

  def test_radio_helper
    request  = ActionController::TestRequest.new
    response = ActionController::TestResponse.new
    request.action = 'test2'
    body = EnumController.process(request, response).body
    assert_equal '<label>low: <input id="test_severity_low" name="test[severity]" type="radio" value="low" /></label><label>medium: <input checked="checked" id="test_severity_medium" name="test[severity]" type="radio" value="medium" /></label><label>high: <input id="test_severity_high" name="test[severity]" type="radio" value="high" /></label><label>critical: <input id="test_severity_critical" name="test[severity]" type="radio" value="critical" /></label>', body
  end


  # Basic tests
  def test_create_basic_default
    assert (object = BasicEnum.create)
    assert_nil object.value,
      "Enum columns without explicit default, default to null if allowed"
    assert !object.new_record?
  end

  def test_create_basic_good
    assert (object = BasicEnum.create(:value => :good))
    assert_equal :good, object.value
    assert !object.new_record?
    assert (object = BasicEnum.create(:value => :working))
    assert_equal :working, object.value
    assert !object.new_record?
  end

  def test_create_basic_null
    assert (object = BasicEnum.create(:value => nil))
    assert_nil object.value
    assert !object.new_record?
  end

  def test_create_basic_bad
    assert (object = BasicEnum.create(:value => :bad))
    assert object.new_record?
  end

  # Basic w/ Default

  ######################################################################

  def test_create_basic_wd_default
    assert (object = BasicDefaultEnum.create)
    assert_equal :working, object.value, "Explicit default ignored columns"
    assert !object.new_record?
  end

  def test_create_basic_wd_good
    assert (object = BasicDefaultEnum.create(:value => :good))
    assert_equal :good, object.value
    assert !object.new_record?
    assert (object = BasicDefaultEnum.create(:value => :working))
    assert_equal :working, object.value
    assert !object.new_record?
  end

  def test_create_basic_wd_null
    assert (object = BasicDefaultEnum.create(:value => nil))
    assert_nil object.value
    assert !object.new_record?
  end

  def test_create_basic_wd_bad
    assert (object = BasicDefaultEnum.create(:value => :bad))
    assert object.new_record?
  end



  # Nonnull

  ######################################################################

  def test_create_nonnull_default
    assert (object = NonnullEnum.create)
#    assert_equal :good, object.value,
#      "Enum columns without explicit default, default to first value if null not allowed"
    assert object.new_record?
  end

  def test_create_nonnull_good
    assert (object = NonnullEnum.create(:value => :good))
    assert_equal :good, object.value
    assert !object.new_record?
    assert (object = NonnullEnum.create(:value => :working))
    assert_equal :working, object.value
    assert !object.new_record?
  end

  def test_create_nonnull_null
    assert (object = NonnullEnum.create(:value => nil))
    assert object.new_record?
  end

  def test_create_nonnull_bad
    assert (object = NonnullEnum.create(:value => :bad))
    assert object.new_record?
  end

  # Nonnull w/ Default

  ######################################################################

  def test_create_nonnull_wd_default
    assert (object = NonnullDefaultEnum.create)
    assert_equal :working, object.value
    assert !object.new_record?
  end

  def test_create_nonnull_wd_good
    assert (object = NonnullDefaultEnum.create(:value => :good))
    assert_equal :good, object.value
    assert !object.new_record?
    assert (object = NonnullDefaultEnum.create(:value => :working))
    assert_equal :working, object.value
    assert !object.new_record?
  end

  def test_create_nonnull_wd_null
    assert (object = NonnullDefaultEnum.create(:value => nil))
    assert object.new_record?
  end

  def test_create_nonnull_wd_bad
    assert (object = NonnullDefaultEnum.create(:value => :bad))
    assert object.new_record?
  end

  def test_quoting
    value = ActiveRecord::Base.send(:sanitize_sql, ["value = ? ", :"'" ] )
    assert_equal "value = '''' ", value
  end
end
