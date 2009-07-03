# == Schema Information
#
# Table name: roles
#
#  id           :integer       not null, primary key
#  name         :string(255)   not null
#  company_id   :integer       not null
#  created_at   :datetime      not null
#  updated_at   :datetime      not null
#  created_by   :integer       
#  updated_by   :integer       
#  lock_version :integer       default(0), not null
#  rights       :text          
#

class Role < ActiveRecord::Base
  belongs_to :company
  has_many :users

  attr_readonly :company_id

  ACTIONS = [ :all,                     # All
              :accountancy,             # Accountant
              :sales                    # Saler
            ]

  #set_column :actions, ACTIONS

  def before_validation
    
#    self.actions_array = self.actions_array # Refresh actions array
  end

#  def can_do?(action=:all)
#    return self.actions_include?(:all) ? true : self.actions_include?(action)
#  end

  def can_do(action)
    #self.actions_set(action)
    #self.save!
  end

  def cannot_do(action)
    #self.actions_set(action, false)
    #self.save!
  end

  def action_name(action)
    lc(action.to_sym)
  end

#    raise Exception.new('Can\'t evaluate action: nil') if action.nil?
#    action = Action.find_by_name(action.to_s) unless action.is_a? Action
#    self.action_ids.include? action.id
#  end

end
