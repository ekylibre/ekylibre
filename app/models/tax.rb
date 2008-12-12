# == Schema Information
# Schema version: 20081127140043
#
# Table name: taxes
#
#  id                   :integer       not null, primary key
#  name                 :string(255)   not null
#  included             :boolean       not null
#  reductible           :boolean       default(TRUE), not null
#  nature               :string(8)     not null
#  amount               :decimal(16, 4 default(0.0), not null
#  description          :text          
#  account_collected_id :integer       
#  account_paid_id      :integer       
#  company_id           :integer       not null
#  created_at           :datetime      not null
#  updated_at           :datetime      not null
#  created_by           :integer       
#  updated_by           :integer       
#  lock_version         :integer       default(0), not null
#

class Tax < ActiveRecord::Base
end
