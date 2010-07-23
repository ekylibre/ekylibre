# = Informations
# 
# == License
# 
# Ekylibre - Simple ERP
# Copyright (C) 2009-2010 Brice Texier, Thibaud Mérigon
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
# == Table: listings
#
#  comment      :text             
#  company_id   :integer          not null
#  conditions   :text             
#  created_at   :datetime         not null
#  creator_id   :integer          
#  id           :integer          not null, primary key
#  lock_version :integer          default(0), not null
#  mail         :text             
#  name         :string(255)      not null
#  query        :text             
#  root_model   :string(255)      not null
#  source       :text             
#  story        :text             
#  updated_at   :datetime         not null
#  updater_id   :integer          
#

class Listing < ActiveRecord::Base
  attr_readonly :company_id
  belongs_to :company
  has_many :nodes, :class_name=>ListingNode.name, :dependent=>:delete_all

#  validates_format_of :query, :with=>/\s*SELECT\s+[^\;]*/
  validates_format_of :query, :conditions, :with=>/^[^\;]*$/

  def before_validation_on_update
    self.query = self.generate
  end

  def root_model_name
    ::I18n.t("activerecord.models."+self.root_model.underscore)
  end

  def root
    self.nodes.find_by_parent_id(nil)||self.nodes.create!(:label=>self.root_model_name, :name=>self.root_model, :nature=>"root")
  end

  def generate
    root = self.root
    query = "SELECT #{self.selected_attr} FROM #{root.model.table_name} AS #{root.name}"
    query += root.complete_query(root.name)
    query += self.query_conditions
    return query
  end

  def selected_attr
    attrs = []
    for node in self.exportable_columns
      #name = I18n::t('activerecord.attributes.'+node.name)
      #attrs << "#{node.parent.key}.#{node.name} AS \"#{name}\" "
      
      name = node.label
      #name = I18n::t('activerecord.attributes.'+node.model.name.underscore+'.'+node.name) ## delete what is after "_" ex: company_0
      attrs << "#{node.name} AS \"#{name}\" "
    end
    attrs = attrs.join(", ")
  end
  
  def query_conditions
    c = " WHERE "
    if self.reflections.size > 0
      cs = []
      for node in self.reflections
        cs << "COALESCE(#{node.name}.#{node.name.match("company") ? '' : 'company_'}id, CURRENT_COMPANY) = CURRENT_COMPANY"
      end
      c += cs.join(" AND ")
      #return c
    end

    cs = []
    for node in self.columns
      if node.condition_operator and node.condition_value and node.condition_operator != "any"
        cs << node.condition
      end
    end
    c += " AND "+cs.join(" AND ") if self.reflections.size > 0 and cs.size > 0
    c += " AND ("+self.conditions+")" unless self.conditions.blank?
    #raise Exception.new self.conditions.blank?
    return c
  end

  def reflections
    self.nodes.find(:all, :conditions=>["nature IN (?)", ["belongs_to", "has_many", "root"]])
  end

  def columns
    self.nodes.find_all_by_nature("column")
  end

  def exportable_columns
    #self.nodes.find_all_by_nature_and_exportable("column", true)
    self.nodes.find(:all, :conditions=>{:nature=>"column", :exportable=>true}, :order=>"position")
  end

  def mail_columns
    self.nodes.find(:all, :conditions=>["name LIKE ? ", '%.email'])
  end

  def duplicate
    listing = self.class.create!(self.attributes.merge(:name=>tg(:copy_of, :source=>self.name)))
    self.root.duplicate(listing)
    listing.reload
    listing.save
    return listing
  end

end
