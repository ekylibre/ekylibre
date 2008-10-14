# == Schema Information
# Schema version: 20080819191919
#
# Table name: impressions
#
#  id            :integer       not null, primary key
#  filename      :string(255)   not null
#  original_name :string(255)     not null
#  template_md5  :string(255)     
#  printed_at    :datetime
#  company_id    :integer


class Impression < ActiveRecord::Base


end
