# == Schema Information
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
#  lock_version  :integer       default(0), not null
#  creator_id    :integer       
#  updater_id    :integer       
#


class Document < ActiveRecord::Base
  belongs_to :company

end
