# == Schema Information
# Schema version: 20081127140043
#
# Table name: accounts
#
#  id           :integer       not null, primary key
#  number       :string(16)    not null
#  alpha        :string(16)    
#  name         :string(208)   not null
#  label        :string(255)   not null
#  usable       :boolean       not null
#  groupable    :boolean       not null
#  keep_entries :boolean       not null
#  transferable :boolean       not null
#  letterable   :boolean       not null
#  pointable    :boolean       not null
#  is_debit     :boolean       not null
#  last_letter  :string(8)     
#  comment      :text          
#  delay_id     :integer       
#  entity_id    :integer       
#  parent_id    :integer       not null
#  company_id   :integer       not null
#  created_at   :datetime      not null
#  updated_at   :datetime      not null
#  created_by   :integer       
#  updated_by   :integer       
#  lock_version :integer       default(0), not null
#

class Account < ActiveRecord::Base


end
