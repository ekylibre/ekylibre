# == Schema Information
# Schema version: 20090223113550
#
# Table name: address_norm_items
#
#  id              :integer       not null, primary key
#  contact_norm_id :integer       not null
#  name            :string(255)   not null
#  nature          :string(15)    default("content"), not null
#  maxlength       :integer       default(38), not null
#  content         :string(255)   
#  left_nature     :string(15)    
#  left_value      :string(63)    
#  right_nature    :string(15)    default("space")
#  right_value     :string(63)    
#  position        :integer       
#  company_id      :integer       not null
#  created_at      :datetime      not null
#  updated_at      :datetime      not null
#  created_by      :integer       
#  updated_by      :integer       
#  lock_version    :integer       default(0), not null
#

class AddressNormItem < ActiveRecord::Base
end
