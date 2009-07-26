# == Schema Information
#
# Table name: establishments
#
#  comment      :text          
#  company_id   :integer       not null
#  created_at   :datetime      not null
#  creator_id   :integer       
#  id           :integer       not null, primary key
#  lock_version :integer       default(0), not null
#  name         :string(255)   not null
#  nic          :string(5)     not null
#  siret        :string(255)   not null
#  updated_at   :datetime      not null
#  updater_id   :integer       
#

class Establishment < ActiveRecord::Base
  belongs_to :company
  has_many :employees
  has_many :stock_locations

  def before_validation
    self.siret = self.company.siren.to_s+self.nic.to_s if self.company
  end
end
