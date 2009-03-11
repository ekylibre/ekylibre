# == Schema Information
# Schema version: 20090311124450
#
# Table name: documents
#
#  id            :integer       not null, primary key
#  filename      :string(255)   
#  original_name :string(255)   not null
#  key           :integer       
#  filesize      :integer       
#  crypt_key     :binary        
#  crypt_mode    :string(255)   not null
#  sha256        :string(255)   not null
#  printed_at    :datetime      
#  company_id    :integer       not null
#  created_at    :datetime      not null
#  updated_at    :datetime      not null
#  created_by    :integer       
#  updated_by    :integer       
#  lock_version  :integer       default(0), not null
#


class Document < ActiveRecord::Base


end
