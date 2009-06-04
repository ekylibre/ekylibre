# == Schema Information
# Schema version: 20090520140946
#
# Table name: establishments
#
#  id           :integer       not null, primary key
#  name         :string(255)   not null
#  nic          :string(5)     not null
#  siret        :string(255)   not null
#  comment      :text          
#  company_id   :integer       not null
#  created_at   :datetime      not null
#  updated_at   :datetime      not null
#  created_by   :integer       
#  updated_by   :integer       
#  lock_version :integer       default(0), not null
#

class Establishment < ActiveRecord::Base
  belongs_to :company
  has_many :employees
  has_many :stock_locations

  def before_validation
    self.siret = self.company.siren.to_s+self.nic.to_s if self.company
  end
end
