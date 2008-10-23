# == Schema Information
# Schema version: 20080819191919
#
# Table name: documents
#
#  id            :integer       not null, primary key
#  filename      :string(255)   not null
#  original_name :string(255)     not null
#  printed_at    :datetime
#  company_id    :integer


class Document < ActiveRecord::Base


end
