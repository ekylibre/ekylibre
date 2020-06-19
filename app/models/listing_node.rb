# = Informations
#
# == License
#
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2009 Brice Texier, Thibaud Merigon
# Copyright (C) 2010-2012 Brice Texier
# Copyright (C) 2012-2014 Brice Texier, David Joulin
# Copyright (C) 2015-2020 Ekylibre SAS
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see http://www.gnu.org/licenses.
#
# == Table: listing_nodes
#
#  attribute_name       :string
#  condition_operator   :string
#  condition_value      :string
#  created_at           :datetime         not null
#  creator_id           :integer
#  depth                :integer          default(0), not null
#  exportable           :boolean          default(TRUE), not null
#  id                   :integer          not null, primary key
#  item_listing_id      :integer
#  item_listing_node_id :integer
#  item_nature          :string
#  item_value           :text
#  key                  :string
#  label                :string           not null
#  lft                  :integer
#  listing_id           :integer          not null
#  lock_version         :integer          default(0), not null
#  name                 :string           not null
#  nature               :string           not null
#  parent_id            :integer
#  position             :integer
#  rgt                  :integer
#  sql_type             :string
#  updated_at           :datetime         not null
#  updater_id           :integer
#

class ListingNode < Ekylibre::Record::Base
  acts_as_list scope: :listing
  acts_as_nested_set scope: :listing
  attr_readonly :listing_id, :nature
  enumerize :nature, in: %i[root column datetime custom boolean string numeric belongs_to has_many]
  belongs_to :listing, inverse_of: :nodes
  belongs_to :item_listing, class_name: 'Listing'
  belongs_to :item_listing_node, class_name: 'ListingNode'
  has_many :items, class_name: 'ListingNodeItem', foreign_key: :node_id, dependent: :destroy
  # [VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates :attribute_name, :condition_operator, :condition_value, :item_nature, :key, :sql_type, length: { maximum: 500 }, allow_blank: true
  validates :depth, presence: true, numericality: { only_integer: true, greater_than: -2_147_483_649, less_than: 2_147_483_648 }
  validates :exportable, inclusion: { in: [true, false] }
  validates :item_value, length: { maximum: 500_000 }, allow_blank: true
  validates :label, :name, presence: true, length: { maximum: 500 }
  validates :lft, :rgt, numericality: { only_integer: true, greater_than: -2_147_483_649, less_than: 2_147_483_648 }, allow_blank: true
  validates :listing, :nature, presence: true
  # ]VALIDATORS]
  validates :item_nature, length: { allow_nil: true, maximum: 10 }
  validates :key, uniqueness: true

  autosave :listing

  @@natures = nature.values

  @@comparators = {
    numeric: %w[any gt lt ge le eq neq vn nvn],
    string: %w[any begins finishes contains equal in not_begins not_finishes not_contains not_equal begins_cs finishes_cs contains_cs equal_cs not_begins_cs not_finishes_cs not_contains_cs not_equal_cs],
    date: %w[any gt lt ge le eq neq vn nvn],
    boolean: %w[any is_true is_false],
    unknown: ['--']
  }
  @@corresponding_comparators = {
    eq: '{{COLUMN}} = {{VALUE}}',
    neq: '{{COLUMN}} != {{VALUE}}',
    gt: '{{COLUMN}} > {{VALUE}}',
    lt: '{{COLUMN}} < {{VALUE}}',
    ge: '{{COLUMN}} >= {{VALUE}}',
    le: '{{COLUMN}} <= {{VALUE}}',
    vn: '{{COLUMN}} IS NULL',
    nvn: '{{COLUMN}} IS NOT NULL',
    begins: 'LOWER({{COLUMN}}) LIKE {{VALUE%}}',
    finishes: 'LOWER({{COLUMN}}) LIKE {{%VALUE}}',
    contains: 'LOWER({{COLUMN}}) LIKE {{%VALUE%}}',
    equal: 'LOWER({{COLUMN}}) = {{VALUE}}',
    begins_cs: '{{COLUMN}} LIKE {{VALUE%}}',
    finishes_cs: '{{COLUMN}} LIKE {{%VALUE}}',
    contains_cs: '{{COLUMN}} LIKE {{%VALUE%}}',
    equal_cs: '{{COLUMN}} = {{VALUE}}',
    not_begins: 'LOWER({{COLUMN}}) NOT LIKE {{VALUE%}}',
    not_finishes: 'LOWER({{COLUMN}}) NOT LIKE {{%VALUE}}',
    not_contains: 'LOWER({{COLUMN}}) NOT LIKE {{%VALUE%}}',
    not_equal: 'LOWER({{COLUMN}}) != {{VALUE}}',
    not_begins_cs: '{{COLUMN}} NOT LIKE {{VALUE%}}',
    not_finishes_cs: '{{COLUMN}} NOT LIKE {{%VALUE}}',
    not_contains_cs: '{{COLUMN}} NOT LIKE {{%VALUE%}}',
    not_equal_cs: '{{COLUMN}} != {{VALUE}}',
    is_true: '{{COLUMN}} = {{VALUE}}',
    is_false: '{{COLUMN}} = {{VALUE}}',
    in: '{{COLUMN}} IN {{LIST}}'
  }

  before_validation do
    self.listing_id = parent.listing_id if parent

    self.key = 'k' + User.send(:generate_password, 31, :normal) if key.blank?
    if root? && listing
      self.name = listing.root_model
    elsif reflection?
      self.name = attribute_name.to_s + '_0'
    elsif parent
      if nature == 'custom'
        self.sql_type = convert_sql_type(parent.model.custom_fields.find_by(column_name: attribute_name).nature.to_s)
        self.name = parent.name.underscore + ".custom_fields->>'#{attribute_name}'"
      elsif parent.model
        self.sql_type = convert_sql_type(parent.model.columns_definition[attribute_name][:type].to_s)
      end
      # raise StandardError.new self.attribute_name.inspect
      self.name ||= parent.name.underscore + '.' + attribute_name
    end
  end

  before_validation(on: :create) do
    if reflection?
      for node in listing.nodes
        if node = listing.nodes.find_by(name: name)
          self.name = node.name.succ
        end
      end
    end
  end

  validate do
    errors.add(:condition_operator, :inclusion) unless condition_operator.blank? || (@@corresponding_comparators.keys + [:any]).include?(condition_operator.to_sym)
  end

  def self.natures
    hash = {}
    @@natures.each { |n| hash[n] = tc('natures.' + n.to_s) }
    hash
  end

  def compute_joins(sql_alias = nil)
    conditions = ''
    children.where('(nature = ? OR nature = ?)', 'belongs_to', 'has_many').find_each do |child|
      parent = sql_alias || name || child.parent.model.table_name
      if child.nature == 'has_many' # or child.nature == "belongs_to"
        conditions += " LEFT JOIN #{child.model.table_name} AS #{child.name} ON (#{child.name}.#{child.reflection.foreign_key} = #{parent}.id)"
      elsif child.nature == 'belongs_to'
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
    # raise StandardError.new self.sql_type.inspect
    # return @@comparators[self.sql_type.to_sym] if self.sql_type
    @@comparators[sql_type.to_sym].collect { |x| [tc('comparators.' + x), x] } if sql_type
  end

  def sql_format_comparator
    @@corresponding_comparators[condition_operator.to_sym] || ' = '
  end

  def condition
    self.class.condition(name, condition_operator, condition_value, nature, sql_type)
  end

  def self.condition(column, operator, value, nature, datatype = 'string')
    operation = @@corresponding_comparators[operator.to_sym] || @@corresponding_comparators[:equal]
    c = operation.gsub('{{COLUMN}}', column)
    c.gsub!('{{LIST}}', '(' + value.to_s.gsub(/\,\,/, "\t").split(/\s*\,\s*/).collect { |x| connection.quote(x.tr("\t", ',')) }.join(', ') + ')')
    c.gsub!(/\{\{[^\}]*VALUE[^\}]*\}\}/) do |m|
      n = m[2..-3].gsub('VALUE', value.to_s.send(operator.to_s =~ /_cs$/ ? 'to_s' : 'lower'))
      #       if datatype == "date"
      #         "'"+connection.quoted_date(value.to_date)+"'"
      if datatype == 'boolean'
        if nature == 'custom'
          operator.to_s == 'is_true' ? "'1'" : "'0'"
        else
          operator.to_s == 'is_true' ? connection.quoted_true : connection.quoted_false
        end
      elsif datatype == 'numeric'
        n
      else
        # "'"+connection.quote(n)+"'"
        connection.quote(n)
      end
    end
    c
  end

  def reflection?
    %w[belongs_to has_many root].include? nature.to_s
  end

  def root?
    parent_id.nil?
  end

  def model
    if root?
      listing.root_model
    else
      parent.model.reflect_on_association(attribute_name).class_name
    end.pluralize.classify.constantize
  rescue
    nil
  end

  def reflection
    return nil unless reflection?
    if root?
      return nil
    else
      return parent.model.reflect_on_association(attribute_name)
    end
  end

  def available_nodes
    nodes = []
    return nodes unless reflection? && model = self.model
    # Columns
    column_nodes = model.content_columns.collect { |x| [model.human_attribute_name(x.name.to_s).to_s, 'column-' + x.name] }
    if model.customizable?
      column_nodes.delete_if { |_, col| col == 'column-custom_fields' }
      model.custom_fields.each do |custom|
        column_nodes << [custom.name, 'special-custom-' + custom.column_name]
      end
    end
    nodes << [tc(:columns), [[tc(:all_columns), 'special-all_columns']] + column_nodes.sort]
    # Reflections
    nodes << [tc(:reflections), model.reflect_on_all_associations.select { |v| %i[has_many belongs_to].include? v.macro }.collect { |r| [model.human_attribute_name(r.name).to_s, "#{r.macro}-#{r.name}"] }.sort]
    nodes
  end

  def convert_sql_type(type)
    # raise StandardError.new type.inspect
    if type == 'decimal' || type == 'integer'
      'numeric'
    elsif type == 'string' || type == 'text'
      'string'
    elsif type == 'date' || type == 'datetime'
      'date'
    elsif type == 'boolean'
      type
    else
      'unknown'
    end
  end

  def default_comparison_value
    if sql_type == 'numeric'
      0
    elsif sql_type == 'string' || sql_type == 'text'
      ''
    elsif sql_type == 'date' || sql_type == 'datetime'
      Time.zone.today
    else
      ''
    end
  end

  def comparison
    if condition_operator && condition_operator != 'any'
      if condition_value
        tc('comparison.with_value', comparator: tc('comparators.' + condition_operator), value: (sql_type == 'date' ? I18n.localize(condition_value.to_date) : condition_value.to_s))
      else
        tc('comparison.without_value', comparator: tc('comparators.' + condition_operator))
      end
    else
      tc(:add_filter)
    end
  end

  def duplicate(listing_clone, parent = nil)
    kepts = %i[attribute_name condition_operator condition_value exportable item_listing_id item_listing_node_id item_nature item_value label name nature position]
    attributes = self.attributes.symbolize_keys.select do |name, _value|
      kepts.include?(name)
    end
    attributes[:listing_id] = listing_clone.id
    attributes[:parent_id]  = (parent ? parent.id : nil)
    node = self.class.create!(attributes)
    for child in children.order(:position)
      child.duplicate(listing_clone, node)
    end
  end
end
