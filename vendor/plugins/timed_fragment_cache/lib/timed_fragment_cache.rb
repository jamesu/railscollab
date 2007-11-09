# Copyright (c) 2006 Richard Livsey
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
# 
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

module ActionController
  module Caching
  
    # Timed Fragment Caching
    # Adds optional expiry to fragment caching which will cache that fragment for the alloted time
    # Works by adding a 'meta' fragment for each timed fragment (inspired by metafragment code in typo
    # http://www.typosphere.org/trac/browser/trunk/vendor/plugins/expiring_action_cache/lib/metafragment.rb)
    # 
    # Works something like this:
    #
    # <% cache 'fragment_name', 10.minutes.from_now do %>
    #  the cached fragment which does something intensive
    # <% end %>
    #
    # This will be cached for 10 minutes before it expires
    #
    # Also adds when_fragment_expired which you can use to only execute code if the fragment is not cached, or has
    # expired:
    #
    # when_fragment_expired 'fragment_name', 10.minutes_from_now do 
    #  # some intensive code
    # end
    #
    # Note that if using the 'when_fragment_expired' in the controller, you don't need the expiry in the call to cache
    # in the template, as 'when_fragment_expired' will expire the fragment for you.
    module TimedFragment
    
      def cache_erb_fragment(block, name = {}, options = nil, expiry = nil)
        unless perform_caching then block.call; return end

        fragment = get_fragment(name)
        if expiry && !fragment
          expire_and_write_meta(name, expiry)  
        end

        buffer = eval("_erbout", block.binding)

        if fragment
          buffer.concat(fragment)
        else
          pos = buffer.length
          block.call
          write_fragment(name, buffer[pos..-1], options)
        end
  
      end
    
      def expiry_time(name)
        read_meta_fragment(name)
      end
    
      def get_fragment(name)
      	return fragments[name] if fragments[name]
      	fragment = read_fragment(name)
        return nil unless fragment
        fragments[name] = fragment
        expires = expiry_time(name)
        return expires && expires > Time.now ? fragment : nil
      end

      def read_meta_fragment(name)
        YAML.load(read_fragment(meta_fragment_key(name))) rescue nil
      end    
    
      def write_meta_fragment(name, meta)
        write_fragment(meta_fragment_key(name), YAML.dump(meta))
      end
    
      def meta_fragment_key(name)
        fragment_cache_key(name) + '_meta'
      end
    
      def when_fragment_expired(name, expiry=nil)
      	return if get_fragment( name )
        yield
        expire_and_write_meta(name, expiry)
      end
    
      def expire_and_write_meta(name, expiry)
        expire_fragment(name)
        write_meta_fragment(name, expiry) if expiry
      end
    
      def fragments
      	@fragments ||= {}
      end
    end
  end
end

module ActionView
  module Helpers
    module TimedFragmentCacheHelper
    
      def self.included(base) # :nodoc:     
        base.class_eval do 
          alias_method :cache, :cache_with_expiry
        end      
      end    
    
      def cache_with_expiry(name = {}, expires = nil, &block)
        @controller.cache_erb_fragment(block, name, nil, expires)
      end
    
    end
  end
end

ActionController::Base.send :include, ActionController::Caching::TimedFragment
ActionView::Base.send(:include, ActionView::Helpers::TimedFragmentCacheHelper)
