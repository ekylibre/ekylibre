# == Schema Information
#
# Table name: mandates
#
#  company_id   :integer       not null
#  created_at   :datetime      not null
#  creator_id   :integer       
#  entity_id    :integer       not null
#  family       :string(255)   not null
#  id           :integer       not null, primary key
#  lock_version :integer       default(0), not null
#  organization :string(255)   not null
#  started_on   :date          
#  stopped_on   :date          
#  title        :string(255)   not null
#  updated_at   :datetime      not null
#  updater_id   :integer       
#

# Generated
