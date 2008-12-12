# == Schema Information
# Schema version: 20081127140043
#
# Table name: invoices
#
#  id                :integer       not null, primary key
#  client_id         :integer       not null
#  nature            :string(1)     not null
#  number            :string(64)    not null
#  price             :decimal(16, 2 default(0.0), not null
#  price_with_taxes  :decimal(16, 2 default(0.0), not null
#  payment_delay_id  :integer       not null
#  payment_on        :date          not null
#  paid              :boolean       not null
#  lost              :boolean       not null
#  has_downpayment   :boolean       not null
#  downpayment_price :decimal(16, 2 default(0.0), not null
#  contact_id        :integer       not null
#  company_id        :integer       not null
#  created_at        :datetime      not null
#  updated_at        :datetime      not null
#  created_by        :integer       
#  updated_by        :integer       
#  lock_version      :integer       default(0), not null
#

class Invoice < ActiveRecord::Base
end
