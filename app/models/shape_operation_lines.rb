# == Schema Information
#
# Table name: shape_operation_lines
#
#  company_id         :integer       not null
#  created_at         :datetime      not null
#  creator_id         :integer       
#  id                 :integer       not null, primary key
#  lock_version       :integer       default(0), not null
#  product_id         :integer       
#  quantity           :decimal(, )   
#  shape_operation_id :integer       not null
#  surface_unit_id    :integer       
#  updated_at         :datetime      not null
#  updater_id         :integer       
#

class ShapeOperationLines < ActiveRecord::Base
end
