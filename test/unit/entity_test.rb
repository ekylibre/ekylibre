# == Schema Information
#
# Table name: entities
#
#  active                    :boolean       default(TRUE), not null
#  activity_code             :string(32)    
#  authorized_payments_count :integer       
#  born_on                   :date          
#  category_id               :integer       
#  client                    :boolean       not null
#  client_account_id         :integer       
#  code                      :string(16)    
#  comment                   :text          
#  company_id                :integer       not null
#  country                   :string(2)     
#  created_at                :datetime      not null
#  creator_id                :integer       
#  dead_on                   :date          
#  deliveries_conditions     :string(60)    
#  discount_rate             :decimal(8, 2) 
#  ean13                     :string(13)    
#  employee_id               :integer       
#  excise                    :string(15)    
#  first_met_on              :date          
#  first_name                :string(255)   
#  full_name                 :string(255)   not null
#  id                        :integer       not null, primary key
#  invoices_count            :integer       
#  language_id               :integer       not null
#  lock_version              :integer       default(0), not null
#  name                      :string(255)   not null
#  nature_id                 :integer       not null
#  origin                    :string(255)   
#  payment_delay_id          :integer       
#  payment_mode_id           :integer       
#  photo                     :string(255)   
#  proposer_id               :integer       
#  reduction_rate            :decimal(8, 2) 
#  reflation_submissive      :boolean       not null
#  siren                     :string(9)     
#  soundex                   :string(4)     
#  supplier                  :boolean       not null
#  supplier_account_id       :integer       
#  updated_at                :datetime      not null
#  updater_id                :integer       
#  vat_number                :string(15)    
#  vat_submissive            :boolean       default(TRUE), not null
#  webpass                   :string(255)   
#  website                   :string(255)   
#

require 'test_helper'

class EntityTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
