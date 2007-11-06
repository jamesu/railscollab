
module ActionView
  module Helpers
    module FormHelper
      # helper to create a select drop down list for the enumerated values. This
      # is the default input tag.
      def enum_select(object_name, method, options = {})
        InstanceTag.new(object_name, method, self, nil, options.delete(:object)).to_enum_select_tag("enum", options)
      end

      # Creates a set of radio buttons for all the enumerated values.
      def enum_radio(object_name, method, options = {})
        InstanceTag.new(object_name, method, self, nil, options.delete(:object)).to_enum_radio_tag("enum", options)        
      end
    end
    
    class InstanceTag #:nodoc:
      alias __to_tag_enum to_tag

      # Add the enumeration tag support. Defaults using the select tag to
      # display the options.
      def to_tag(options = {})
        if column_type == :enum
          to_enum_select_tag(options)
        else
          __to_tag_enum(options)
        end
      end

      # Create a select tag and one option for each of the
      # enumeration values.
      def to_enum_select_tag(values, options = {})
        # Remove when we no longer support 1.1.
        begin
          v = value(object)
        rescue ArgumentError
          v = value
        end
        add_default_name_and_id(options)
        tag_text = "<select"
        tag_text << tag_options(options)
        tag_text << ">"
        values = enum_values
        raise ArgumentError, "No values for enum select tag" unless values
        values.each do |enum|
          tag_text << "<option value=\"#{enum}\""
          tag_text << ' selected="selected"' if v and v == enum
          tag_text << ">#{enum}</option>"
        end
        tag_text << "</select>"
      end

      # Creates a set of radio buttons and labels.
      def to_enum_radio_tag(values, options = {})
        # Remove when we no longer support 1.1.
        begin
          v = value(object)
        rescue ArgumentError
          v = value
        end
        add_default_name_and_id(options)
        values = enum_values
        raise ArgumentError, "No values for enum select tag" unless values
        tag_text = ''
        template = options.dup
        template.delete('checked')
        values.each do |enum|
          opts = template.dup
          opts['checked'] = 'checked' if v and v == enum
          opts['id'] = "#{opts['id']}_#{enum}"
          tag_text << "<label>#{enum}: "
          tag_text << to_radio_button_tag(enum, opts)
          tag_text << "</label>"
        end
        tag_text
      end

      # Gets the list of values for the column.
      def enum_values
        object.send("column_for_attribute", @method_name).values
      end
    end
  end
end
