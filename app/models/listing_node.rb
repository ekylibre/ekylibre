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
# == Table: listing_nodes
#
#  attribute_name       :string(255)
#  condition_operator   :string(255)
#  condition_value      :string(255)
#  created_at           :datetime         not null
#  creator_id           :integer
#  depth                :integer          default(0), not null
#  exportable           :boolean          default(TRUE), not null
#  id                   :integer          not null, primary key
#  item_listing_id      :integer
#  item_listing_node_id :integer
#  item_nature          :string(10)
#  item_value           :text
#  key                  :string(255)
#  label                :string(255)      not null
#  lft                  :integer
#  listing_id           :integer          not null
#  lock_version         :integer          default(0), not null
#  name                 :string(255)      not null
#  nature               :string(255)      not null
#  parent_id            :integer
#  position             :integer
#  rgt                  :integer
#  sql_type             :string(255)
#  updated_at           :datetime         not null
#  updater_id           :integer
#


class ListingNode < Ekylibre::Record::Base
  acts_as_list :scope => :listing
  acts_as_nested_set
  attr_readonly :listing_id, :nature
  enumerize :nature, in: [:root, :column, :datetime, :boolean, :string, :numeric, :belongs_to, :has_many]
  belongs_to :listing, inverse_of: :nodes
  belongs_to :item_listing, class_name: "Listing"
  belongs_to :item_listing_node, class_name: "ListingNode"
  has_many :items, class_name: "ListingNodeItem"
  #[VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_numericality_of :depth, :lft, :rgt, allow_nil: true, only_integer: true
  validates_length_of :item_nature, allow_nil: true, maximum: 10
  validates_length_of :attribute_name, :condition_operator, :condition_value, :key, :label, :name, :nature, :sql_type, allow_nil: true, maximum: 255
  validates_inclusion_of :exportable, in: [true, false]
  validates_presence_of :depth, :label, :listing, :name, :nature
  #]VALIDATORS]
  validates_uniqueness_of :key

  autosave :listing

  @@natures = self.nature.values

  @@comparators = {
    :numeric => ["any", "gt", "lt", "ge", "le", "eq", "neq", "vn", "nvn"],
    :string => ["any", "begins", "finishes", "contains", "equal", "in", "not_begins", "not_finishes", "not_contains", "not_equal", "begins_cs", "finishes_cs", "contains_cs", "equal_cs", "not_begins_cs", "not_finishes_cs", "not_contains_cs", "not_equal_cs"],
    :date => ["any", "gt", "lt", "ge", "le", "eq", "neq", "vn", "nvn"],
    :boolean => ["any", "is_true", "is_false"],
    :unknown => ["--"]
  }
  @@corresponding_comparators = {
    :eq => "{{COLUMN}} = {{VALUE}}",
    :neq => "{{COLUMN}} != {{VALUE}}",
    :gt => "{{COLUMN}} > {{VALUE}}",
    :lt => "{{COLUMN}} < {{VALUE}}",
    :ge => "{{COLUMN}} >= {{VALUE}}",
    :le => "{{COLUMN}} <= {{VALUE}}",
    :vn => "{{COLUMN}} IS NULL",
    :nvn => "{{COLUMN}} IS NOT NULL",
    :begins => "LOWER({{COLUMN}}) LIKE {{VALUE%}}",
    :finishes => "LOWER({{COLUMN}}) LIKE {{%VALUE}}",
    :contains => "LOWER({{COLUMN}}) LIKE {{%VALUE%}}",
    :equal => "LOWER({{COLUMN}}) = {{VALUE}}",
    :begins_cs => "{{COLUMN}} LIKE {{VALUE%}}",
    :finishes_cs => "{{COLUMN}} LIKE {{%VALUE}}",
    :contains_cs => "{{COLUMN}} LIKE {{%VALUE%}}",
    :equal_cs => "{{COLUMN}} = {{VALUE}}",
    :not_begins => "LOWER({{COLUMN}}) NOT LIKE {{VALUE%}}",
    :not_finishes => "LOWER({{COLUMN}}) NOT LIKE {{%VALUE}}",
    :not_contains => "LOWER({{COLUMN}}) NOT LIKE {{%VALUE%}}",
    :not_equal => "LOWER({{COLUMN}}) != {{VALUE}}",
    :not_begins_cs => "{{COLUMN}} NOT LIKE {{VALUE%}}",
    :not_finishes_cs => "{{COLUMN}} NOT LIKE {{%VALUE}}",
    :not_contains_cs => "{{COLUMN}} NOT LIKE {{%VALUE%}}",
    :not_equal_cs => "{{COLUMN}} != {{VALUE}}",
    :is_true => "{{COLUMN}} = {{VALUE}}",
    :is_false => "{{COLUMN}} = {{VALUE}}",
    in: "{{COLUMN}} IN {{LIST}}"
  }

  before_validation do
    self.listing_id = self.parent.listing_id if self.parent

    self.key = 'k'+User.send(:generate_password, 31, :normal) if self.key.blank?
    if self.root?
      self.name = self.listing.root_model
    elsif self.reflection?
      self.name = self.attribute_name.to_s+"_0"
    else
      if self.parent.model
        self.sql_type = self.convert_sql_type(self.parent.model.columns_definition[self.attribute_name][:type].to_s)
      end
      #raise StandardError.new self.attribute_name.inspect
      self.name = self.parent.name.underscore+"."+self.attribute_name
    end
  end

  before_validation(on: :create) do
    if self.reflection?
      for node in listing.nodes
        if node = self.listing.nodes.where(:name => self.name).first
          self.name = node.name.succ
        end
      end
    end
  end

  validate do
    errors.add(:condition_operator, :inclusion) unless self.condition_operator.blank? or (@@corresponding_comparators.keys+[:any]).include?(self.condition_operator.to_sym)
  end

  def self.natures
    hash = {}
    @@natures.each{|n| hash[n] = tc('natures.'+n.to_s) }
    hash
  end

  def compute_joins(sql_alias=nil)
    conditions = ""
    for child in self.children.where("(nature = ? OR nature = ?)", 'belongs_to', 'has_many')
      parent = sql_alias||self.name||child.parent.model.table_name
      if child.nature == "has_many" #or child.nature == "belongs_to"
        conditions += " LEFT JOIN #{child.model.table_name} AS #{child.name} ON (#{child.name}.#{child.reflection.foreign_key} = #{parent}.id)"
      elsif child.nature == "belongs_to"
        conditions += " LEFT JOIN #{child.model.table_name} AS #{child.name} ON (#{parent}.#{child.reflection.foreign_key} = #{child.name}.id)"
      end
      conditions += child.compute_joins
    end
    conditions
  end

  def joins
    self
  end

  def comparators
    #raise StandardError.new self.sql_type.inspect
    #return @@comparators[self.sql_type.to_sym] if self.sql_type
    @@comparators[self.sql_type.to_sym].collect{|x| [I18n::t('models.listing_node.comparators.'+x),x]} if self.sql_type
  end

  def sql_format_comparator
    @@corresponding_comparators[self.condition_operator.to_sym]||" = "
  end

  def condition
    return self.class.condition(self.name, self.condition_operator, self.condition_value, self.sql_type)
  end


  def self.condition(column, operator, value, datatype="string")
    operation =  @@corresponding_comparators[operator.to_sym]||@@corresponding_comparators[:equal]
    c = operation.gsub("{{COLUMN}}", column)
    c.gsub!("{{LIST}}", "("+value.to_s.gsub(/\,\,/, "\t").split(/\s*\,\s*/).collect{|x| connection.quote(x.gsub(/\t/, ','))}.join(", ")+")")
    c.gsub!(/\{\{[^\}]*VALUE[^\}]*\}\}/) do |m|
      n = m[2..-3].gsub("VALUE", value.to_s.send(operator.to_s.match(/_cs$/) ? "to_s" : "lower"))
#       if datatype == "date"
#         "'"+connection.quoted_date(value.to_date)+"'"
      if datatype == "boolean"
        (operator.to_s == "is_true" ? connection.quoted_true : connection.quoted_false)
      elsif datatype == "numeric"
        n
      else
        # "'"+connection.quote(n)+"'"
        connection.quote(n)
      end
    end
    return c
  end


  def compute_condition

  end

  def reflection?
    ["belongs_to", "has_many", "root"].include? self.nature.to_s
  end

  def root?
    self.parent_id.nil?
  end

  def model
    if self.root?
      self.listing.root_model
    else
      self.parent.model.reflections[self.attribute_name.to_sym].class_name
    end.pluralize.classify.constantize rescue nil
  end

  def reflection
    return nil unless self.reflection?
    if self.root?
      return nil
    else
      return self.parent.model.reflections[self.attribute_name.to_sym]
    end
  end

  def available_nodes
    nodes = []
    # raise self.attribute_name.to_sym.inspect
    # raise self.parent.model.reflections.keys.inspect
    # raise self.parent.model.reflections[self.attribute_name.to_sym].class_name.inspect
    return nodes unless self.reflection? and model = self.model
    # Columns
    nodes << [tc(:columns), [[tc(:all_columns), 'special.all_columns']] + model.content_columns.collect{|x| [model.human_attribute_name(x.name.to_s).to_s, "column-"+x.name]}.sort ]
    # Reflections
    nodes << [tc(:reflections), model.reflections.select{|k,v| [:has_many, :belongs_to].include? v.macro}.collect{|a,b| [model.human_attribute_name(a.to_s).to_s, b.macro.to_s+"-"+a.to_s]}.sort ]
    return nodes
  end

  def convert_sql_type(type)
    #raise StandardError.new type.inspect
    if type == "decimal" or type == "integer"
      return 'numeric'
    elsif type == "string" or type == "text"
      return "string"
    elsif type == "date" or type == "datetime"
      return "date"
    elsif type == "boolean"
      return type
    else
      return 'unknown'
    end
  end

  def default_comparison_value
    if self.sql_type == "numeric"
      return 0
    elsif self.sql_type == "string" or self.sql_type == "text"
      return ""
    elsif self.sql_type == "date" or self.sql_type == "datetime"
      return Date.today
    else
      return ""
    end
  end

  def comparison
    if self.condition_operator and self.condition_operator != "any"
      if self.condition_value
        return tc('comparison.with_value', :comparator => tc('comparators.'+self.condition_operator), :value => (self.sql_type=="date" ? I18n.localize(self.condition_value.to_date) : self.condition_value.to_s))
      else
        return tc('comparison.without_value', :comparator => tc('comparators.'+self.condition_operator))
      end
    else
      return tc(:add_filter)
    end
  end

  def duplicate(listing_clone, parent = nil)
    kepts = [:attribute_name, :condition_operator, :condition_value, :exportable, :item_listing_id, :item_listing_node_id, :item_nature, :item_value, :label, :name, :nature, :position]
    attributes = self.attributes.symbolize_keys.select do |name, value|
      kepts.include?(name)
    end
    attributes[:listing_id] = listing_clone.id
    attributes[:parent_id]  = (parent ? parent.id : nil)
    node = self.class.create!(attributes)
    for child in self.children.order(:position)
      child.duplicate(listing_clone, node)
    end
  end

end
