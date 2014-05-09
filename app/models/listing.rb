# = Informations
#
# == License
#
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2009-2012 Brice Texier, Thibaud Merigon
# Copyright (C) 2012-2014 Brice Texier, David Joulin
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
#  conditions   :text
#  created_at   :datetime         not null
#  creator_id   :integer
#  description  :text
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


class Listing < Ekylibre::Record::Base
  # attr_accessible :name, :root_model, :description, :conditions
  attr_readonly :root_model
  enumerize :root_model, in: Ekylibre::Schema.models
  has_many :columns, -> { where("nature = ?", "column") }, class_name: "ListingNode"
  has_many :exportable_columns, -> { where(:nature => "column", :exportable => true).order("position") }, class_name: "ListingNode"
  has_many :filtered_columns, -> { where("nature = ? AND condition_operator IS NOT NULL AND condition_operator != '' AND condition_operator != ? ", "column", "any") }, class_name: "ListingNode"
  has_many :coordinate_columns, -> { where("name LIKE ? AND nature = ? ", '%.coordinate', "column") }, class_name: "ListingNode"
  has_many :nodes, class_name: "ListingNode", dependent: :delete_all, inverse_of: :listing
  has_many :reflection_nodes, -> { where(nature: ["belongs_to", "has_many", "root"]) }, class_name: "ListingNode"
  has_one :root_node, -> {where(parent_id: nil)}, class_name: "ListingNode"

  #[VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_length_of :name, :root_model, allow_nil: true, maximum: 255
  validates_presence_of :name, :root_model
  #]VALIDATORS]
  validates_format_of :query, :conditions, :with => /\A[^\;]*\z/

  before_validation(on: :update) do
    self.query = self.generate
  end

  def root_model_name
    # ::I18n.t("activerecord.models."+self.root_model.underscore)
    self.root_model.classify.constantize.model_name.human rescue '???'
  end

  def root
    self.root_node || self.nodes.create!(label: self.root_model_name, name: self.root_model, nature: "root")
  end

  def generate
    query = ""
    begin
      conn = self.class.connection
      root = self.root
      query = "SELECT "+self.exportable_columns.collect{|n| "#{n.name} AS "+conn.quote_column_name(n.label)}.join(", ")
      query << " FROM #{root.model.table_name} AS #{root.name}"+root.compute_joins
      unless self.compute_where.blank?
        query << " WHERE " + self.compute_where
      end
      unless self.exportable_columns.size.zero?
        query << " ORDER BY " + self.exportable_columns.collect{|n| n.name}.join(", ")
      end
    rescue
      query = ""
    end
    return query
  end


  def compute_where
    conn = self.class.connection
    c = ""
    if klass = self.root_model.classify.constantize rescue nil
      if klass.columns_definition[:type]
        c << "#{root.name}.type = '#{klass.name}'"
      end
    end
    #  No reflections => no columns => no conditions
    return c unless self.reflection_nodes.any?
    # Filter on columns
    if self.filtered_columns.any?
      c << " AND " unless c.blank?
      c << self.filtered_columns.map(&:condition).join(" AND ")
    end
    # General conditions
    unless self.conditions.blank?
      c << " AND " unless c.blank?
      c << "(" + self.conditions + ")"
    end
    return c
  end

  # Fully duplicate a listing
  def duplicate
    listing = self.class.create!(self.attributes.merge(name: tg(:copy_of, :source => self.name)).delete_if{|a| ["id", "lock_version"].include?(a.to_s)})
    self.root_node.duplicate(listing)
    return listing
  end

  def can_mail?
    self.coordinate_columns.any?
  end

end
