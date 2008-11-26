# == Schema Information
# Schema version: 20080819191919
#
# Table name: widgets
#
#  id           :integer       not null, primary key
#  name         :string(255)   not null
#  nature       :string(255)   not null
#  options      :text          
#  position     :integer       
#  location_id  :integer       not null
#  company_id   :integer       not null
#  created_at   :datetime      not null
#  updated_at   :datetime      not null
#  created_by   :integer       
#  updated_by   :integer       
#  lock_version :integer       default(0), not null
#

class Widget < ActiveRecord::Base
  acts_as_list :scope=>:location

  def render(user)
    if self.methods.include?('render_'+self.nature.to_s)
      self.send('render_'+self.nature.to_s, user)
    else
      '<div class="partial" style="text-align:center;"><strong>No renderer for '+self.nature.to_s+'</strong></div>'
    end
  end

  def options
    @options_hash = self[:options].to_hash
  end

  def options=(hash)
#    self[:options]={:a=>'ok'}
#    self.options
    @options_hash = hash
    self[:options] = @options_hash.to_string
  end

end


module Ekylibre
  module Widgets
    include ActionView::Helpers::TagHelper

    def render_content(user)
      code  = content_tag(:h2, 'Content Widget')
      code += content_tag(:div, 'Test')
      content_tag(:div, code, :class=>:partial, :style=>'text-align:center;')
    end
    
  end
end

::Widget.send(:include, Ekylibre::Widgets)
