# == Schema Information
# Schema version: 20081127140043
#
# Table name: purchase_orders
#
#  id                :integer       not null, primary key
#  client_id         :integer       not null
#  number            :string(64)    not null
#  shipped           :boolean       not null
#  invoiced          :boolean       not null
#  amount            :decimal(16, 2 default(0.0), not null
#  amount_with_taxes :decimal(16, 2 default(0.0), not null
#  dest_contact_id   :integer       not null
#  comment           :text          
#  company_id        :integer       not null
#  created_at        :datetime      not null
#  updated_at        :datetime      not null
#  created_by        :integer       
#  updated_by        :integer       
#  lock_version      :integer       default(0), not null
#

class PurchaseOrder < ActiveRecord::Base
end
