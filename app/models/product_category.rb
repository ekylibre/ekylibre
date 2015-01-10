# = Informations
# 
# == License
# 
# Ekylibre - Simple ERP
# Copyright (C) 2009-2015 Brice Texier, Thibaud Merigon
# 
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see http://www.gnu.org/licenses.
# 
# == Table: product_categories
#
#  catalog_description :text             
#  catalog_name        :string(255)      not null
#  comment             :text             
#  company_id          :integer          not null
#  created_at          :datetime         not null
#  creator_id          :integer          
#  id                  :integer          not null, primary key
#  lock_version        :integer          default(0), not null
#  name                :string(255)      not null
#  parent_id           :integer          
#  published           :boolean          not null
#  updated_at          :datetime         not null
#  updater_id          :integer          
#


class ProductCategory < CompanyRecord
  #[VALIDATORS[
  # Do not edit these lines directly. Use `rake clean:validations`.
  validates_length_of :catalog_name, :name, :allow_nil => true, :maximum => 255
  validates_inclusion_of :published, :in => [true, false]
  validates_presence_of :catalog_name, :company, :name
  #]VALIDATORS]
  acts_as_tree
  attr_readonly :company_id
  belongs_to :company
  has_many :products, :foreign_key => :category_id
  validates_uniqueness_of :name, :scope => :company_id

  before_validation do
    self.catalog_name = self.name if self.catalog_name.blank?
  end

  def to_s
    self.name
  end

  def depth
    if self.parent.nil?
      0
    else
      self.parent.depth+1
    end
  end

end
