# == Schema Information
# Schema version: 20080819191919
#
# Table name: locations
#
#  id           :integer       not null, primary key
#  name         :string(255)   not null
#  created_at   :datetime      not null
#  updated_at   :datetime      not null
#  created_by   :integer       
#  updated_by   :integer       
#  lock_version :integer       default(0), not null
#

class Location < ActiveRecord::Base
  def render(user)
    widgets = Widget.find(:all, :conditions=>{:location_id=>self.id}, :order=>:position)
    code = ''
    for widget in widgets
      code += widget.render(user)
    end
    code
  end
end
