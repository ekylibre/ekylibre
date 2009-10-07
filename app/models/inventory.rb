# == Schema Information
#
# Table name: inventories
#
#  changes_reflected :boolean       
#  comment           :text          
#  company_id        :integer       not null
#  created_at        :datetime      not null
#  creator_id        :integer       
#  date              :date          not null
#  employee_id       :integer       
#  id                :integer       not null, primary key
#  lock_version      :integer       default(0), not null
#  updated_at        :datetime      not null
#  updater_id        :integer       
#

class Inventory < ActiveRecord::Base

  belongs_to :company
  belongs_to :employee
  has_many :lines,  :class_name=>InventoryLine.name

  attr_readonly :company_id


  def before_validation
    self.date ||= Date.today
  end

  def after_update
    if self.changes_reflected
      for line in self.lines
        line.save
      end
    end
  end

  def before_destroy
    for line in self.lines
      line.destroy
    end
  end


end
