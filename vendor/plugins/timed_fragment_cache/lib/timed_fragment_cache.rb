# Copyright (c) 2006 Richard Livsey, 2008 Steffen Rusitschka
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
    
      def self.included(base) # :nodoc:     
        base.class_eval do 
          alias_method :write_fragment_without_expiry, :write_fragment
          alias_method :write_fragment, :write_fragment_with_expiry
        end      
      end
            
      def write_fragment_with_expiry(name, content, options = nil, expiry = nil)
        unless perform_caching then return content end

        if expiry && fragment_expired?(name)
          expire_and_write_meta(name, expiry)  
        end
        
        write_fragment_without_expiry(name, content, options)          
      end
    
      def expiry_time(name)
        read_meta_fragment(name)
      end
    
      def fragment_expired?(name)
        return true unless read_fragment(name)
        expires = expiry_time(name)
        expires.nil? || expires < Time.now
      end
    
      def read_meta_fragment(name)
        YAML.load(read_fragment(meta_fragment_key(name))) rescue nil
      end    
    
      def write_meta_fragment(name, meta)
        write_fragment_without_expiry(meta_fragment_key(name), YAML.dump(meta))
      end
    
      def meta_fragment_key(name)
        fragment_cache_key(name) + '_meta'
      end
    
      def when_fragment_expired(name, expiry=nil)
        return unless fragment_expired?(name)
        
        yield
        expire_and_write_meta(name, expiry)
      end
    
      def expire_and_write_meta(name, expiry)
        expire_fragment(name)
        write_meta_fragment(name, expiry) if expiry
      end
    
    end
  end
end

module ActionView
  module Helpers
    module TimedFragmentCacheHelper
    
      def self.included(base) # :nodoc:     
        base.class_eval do 
          alias_method :cache_without_expiry, :cache
          alias_method :cache, :cache_with_expiry
        end      
      end    
    
      def cache_with_expiry(name = {}, expires = nil, &block)
        if expires && @controller.fragment_expired?(name)
          @controller.expire_and_write_meta(name, expires)
        end
        cache_without_expiry(name, &block)
      end
    
    end
  end
end

ActionController::Base.send :include, ActionController::Caching::TimedFragment
ActionView::Base.send(:include, ActionView::Helpers::TimedFragmentCacheHelper)