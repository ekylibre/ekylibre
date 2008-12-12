# == Schema Information
# Schema version: 20081127140043
#
# Table name: sale_orders
#
#  id                  :integer       not null, primary key
#  client_id           :integer       not null
#  nature_id           :integer       not null
#  number              :string(64)    not null
#  invoiced            :boolean       not null
#  price               :decimal(16, 2 default(0.0), not null
#  price_with_taxes    :decimal(16, 2 default(0.0), not null
#  state               :string(1)     default("O"), not null
#  expiration_id       :integer       not null
#  expired_on          :date          not null
#  payment_delay_id    :integer       not null
#  has_downpayment     :boolean       not null
#  downpayment_price   :decimal(16, 2 default(0.0), not null
#  contact_id          :integer       not null
#  invoice_contact_id  :integer       not null
#  delivery_contact_id :integer       not null
#  object              :string(255)   
#  function_title      :string(255)   
#  introduction        :text          
#  conclusion          :text          
#  comment             :text          
#  company_id          :integer       not null
#  created_at          :datetime      not null
#  updated_at          :datetime      not null
#  created_by          :integer       
#  updated_by          :integer       
#  lock_version        :integer       default(0), not null
#

class SaleOrder < ActiveRecord::Base
end
