# == Schema Information
# Schema version: 20080819191919
#
# Table name: roles
#
#  id           :integer       not null, primary key
#  name         :string(255)   not null
#  default      :boolean       not null
#  company_id   :integer       not null
#  created_at   :datetime      not null
#  updated_at   :datetime      not null
#  created_by   :integer       
#  updated_by   :integer       
#  lock_version :integer       default(0), not null
#

class Role < ActiveRecord::Base

  def can_do?(action)
    raise Exception.new 'Can\'t evaluate action: nil' if action.nil?
    action = Action.find_by_name(action.to_s) unless action.is_a? Action
    self.action_ids.include? action.id
  end

end
