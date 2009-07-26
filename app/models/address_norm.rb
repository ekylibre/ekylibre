# == Schema Information
#
# Table name: address_norms
#
#  align        :string(8)     default("left"), not null
#  company_id   :integer       not null
#  created_at   :datetime      not null
#  creator_id   :integer       
#  default      :boolean       not null
#  id           :integer       not null, primary key
#  lock_version :integer       default(0), not null
#  name         :string(255)   not null
#  reference    :string(255)   
#  rtl          :boolean       not null
#  updated_at   :datetime      not null
#  updater_id   :integer       
#

class AddressNorm < ActiveRecord::Base
  belongs_to :company
  has_many :items, :class_name=>AddressNormItem.to_s
  has_many :contacts

end
