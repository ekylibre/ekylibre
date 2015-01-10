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


class Listing < CompanyRecord
  #[VALIDATORS[
  # Do not edit these lines directly. Use `rake clean:validations`.
  validates_length_of :name, :root_model, :allow_nil => true, :maximum => 255
  #]VALIDATORS]
  attr_readonly :company_id
  belongs_to :company
  has_many :columns, :class_name=>"ListingNode", :conditions=>["nature = ?", "column"]
  has_many :exportable_columns, :class_name=>"ListingNode", :conditions=>{:nature=>"column", :exportable=>true}, :order=>"position"
  has_many :filtered_columns, :class_name=>"ListingNode", :conditions=>["nature = ? AND condition_operator IS NOT NULL AND condition_operator != '' AND condition_operator != ? ", "column", "any"]
  has_many :mail_columns, :class_name=>"ListingNode", :conditions=>["name LIKE ? AND nature = ? ", '%.email', "column"]
  has_many :nodes, :class_name=>"ListingNode", :dependent=>:delete_all
  has_many :reflections, :class_name=>"ListingNode", :conditions=>["nature IN (?)", ["belongs_to", "has_many", "root"]]

#  validates_format_of :query, :with=>/\s*SELECT\s+[^\;]*/
  validates_format_of :query, :conditions, :with=>/^[^\;]*$/

  before_validation(:on=>:update) do
    self.query = self.generate
  end

  def root_model_name
    # ::I18n.t("activerecord.models."+self.root_model.underscore)
    self.root_model.classify.constantize.model_name.human rescue '???'
  end

  def root
    self.nodes.find_by_parent_id(nil)||self.nodes.create!(:label=>self.root_model_name, :name=>self.root_model, :nature=>"root")
  end

  def generate
    query = ""
    begin
      conn = self.class.connection
      root = self.root
      query = "SELECT "+self.exportable_columns.collect{|n| "#{n.name} AS "+conn.quote_column_name(n.label)}.join(", ")
      query += " FROM #{root.model.table_name} AS #{root.name}"+root.compute_joins
      query += " WHERE "+self.compute_where
      query += " ORDER BY "+self.exportable_columns.collect{|n| n.name}.join(", ")
    rescue
      query = ""
    end
    return query
  end

  
  def compute_where
    conn = self.class.connection
    c = ""
    # Filter on company
    if self.reflections.size > 0
      c += self.reflections.collect do |node|
        "COALESCE("+conn.quote_table_name(node.name)+"."+conn.quote_column_name("#{'company_' unless node.name.match("company")}id")+", CURRENT_COMPANY) = CURRENT_COMPANY"
      end.join(" AND ")
    else
      #  No reflections => no columns => no conditions
      return ""
    end

    if self.filtered_columns.size > 0
      c += " AND "+self.filtered_columns.collect{ |node| node.condition }.join(" AND ")
    end
    c += " AND ("+self.conditions+")" unless self.conditions.blank?
    return c
  end

  def duplicate
    listing = self.class.create!(self.attributes.merge(:name=>tg(:copy_of, :source=>self.name)))
    self.root.duplicate(listing)
    listing.reload
    listing.save
    return listing
  end

end
