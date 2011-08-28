#==
# RailsCollab
# Copyright (C) 2007 - 2008 James S Urquhart
# Portions Copyright (C) René Scheibe
# 
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
# 
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#++

class String
  def twist(twister)
    return self if self.length != twister.length

    untwist_arr = self.split('')
    twist_arr = twister.clone()
    twister.length.times do |ti|
      twist_arr[twister[ti]] = untwist_arr[ti]
    end

    twist_arr.join()
  end

  def untwist(twister)
    return self if self.length != twister.length

    twist_arr = self.split('')
    untwist_arr = twister.clone()
    twister.length.times do |ti|
      untwist_arr[ti] = twist_arr[twister[ti]]
    end

    untwist_arr.join()
  end

  def valid_hash?
    (self =~ /^([a-f0-9]*)$/) != nil
  end

  def sanitize_filename
    fname = File.basename(self)
    fname.gsub(/[^\w\.\-]/, '_')
  end

  def excerpt(chars=100, more='...')
    self.length > chars ? "#{self[0...chars]}#{more}" : self
  end
end
