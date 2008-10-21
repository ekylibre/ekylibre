# == Schema Information
# Schema version: 20080819191919
#
# Table name: templates
#
#  id           :integer       not null, primary key
#  name         :string(255)   not null
#  content      :text          not null
#  cache        :text          
#  company_id   :integer       not null
#  created_at   :datetime      not null
#  updated_at   :datetime      not null
#  created_by   :integer       
#  updated_by   :integer       
#  lock_version :integer       default(0), not null
#

class Template < ActiveRecord::Base
  # the column md5 is fulled with the MD5 of the content template.
  def before_save
    self.md5=Digest::MD5.hexdigest(self.content)
   
  end
end
