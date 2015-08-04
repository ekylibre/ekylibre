# = Informations
#
# == License
#
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2009 Brice Texier, Thibaud Merigon
# Copyright (C) 2010-2012 Brice Texier
# Copyright (C) 2012-2015 Brice Texier, David Joulin
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
# == Table: preferences
#
#  boolean_value     :boolean
#  created_at        :datetime         not null
#  creator_id        :integer
#  decimal_value     :decimal(19, 4)
#  id                :integer          not null, primary key
#  integer_value     :integer
#  lock_version      :integer          default(0), not null
#  name              :string           not null
#  nature            :string           not null
#  record_value_id   :integer
#  record_value_type :string
#  string_value      :text
#  updated_at        :datetime         not null
#  updater_id        :integer
#  user_id           :integer
#

class Preference < Ekylibre::Record::Base
  # attr_accessible :nature, :name, :value
  enumerize :nature, in: [:chart_of_accounts, :country, :currency, :boolean, :decimal, :language, :integer, :record, :spatial_reference_system, :string], default: :string, predicates: true
  @@natures = nature.values
  @@conversions = { float: :decimal, true_class: :boolean, false_class: :boolean, fixnum: :integer }
  cattr_reader :reference
  attr_readonly :user_id, :name, :nature
  belongs_to :user, class_name: 'Entity'
  belongs_to :record_value, polymorphic: true
  # cattr_reader :reference
  # [VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_numericality_of :integer_value, allow_nil: true, only_integer: true
  validates_numericality_of :decimal_value, allow_nil: true
  validates_presence_of :name, :nature
  # ]VALIDATORS]
  validates_length_of :nature, allow_nil: true, maximum: 60
  validates_inclusion_of :nature, in: @@natures
  validates_uniqueness_of :name, scope: [:user_id]

  alias_attribute :chart_of_accounts_value, :string_value
  alias_attribute :country_value, :string_value
  alias_attribute :currency_value, :string_value
  alias_attribute :language_value, :string_value
  alias_attribute :spatial_reference_system_value, :string_value

  scope :global, -> { where(name: @@reference.keys.map(&:to_s), user_id: nil) }

  def self.prefer(name, nature, default_value = nil)
    @@reference ||= HashWithIndifferentAccess.new
    unless self.nature.values.include?(nature.to_s)
      fail ArgumentError, "Nature (#{nature.inspect}) is unacceptable. #{self.nature.values.to_sentence} are accepted."
    end
    @@reference[name] = { name: :name, nature: nature.to_sym, default: default_value }
  end

  prefer :bookkeep_automatically, :boolean, true
  prefer :bookkeep_in_draft, :boolean, true
  prefer :detail_payments_in_deposit_bookkeeping, :boolean, true
  prefer :host, :string, 'erp.example.com'
  prefer :use_entity_codes_for_account_numbers, :boolean, true
  prefer :sales_conditions, :string, ''
  prefer :chart_of_accounts, :chart_of_accounts, Nomen::ChartsOfAccounts.default
  prefer :language, :language, Nomen::Languages.default
  prefer :country,  :country, Nomen::Countries.default
  prefer :currency, :currency, Nomen::Currencies.default
  # prefer :map_measure_srid, :integer, 0
  prefer :map_measure_srs, :spatial_reference_system, Nomen::SpatialReferenceSystems.default

  before_validation do
    self.record_value_type = record_value.class.base_class.name if self.record?
  end

  def self.check!
    reference.keys.each do |pref|
      get(pref)
    end
  end

  def self.type_to_nature(object)
    klass = object.class.to_s
    if object.is_a?(Nomen::Item) && nature = object.nomenclature.name.to_s.singularize.to_sym and nature.values.include?(nature)
      nature
    elsif %w(String Symbol).include? klass
      :string
    elsif %w(Integer Fixnum Bignum).include? klass
      :integer
    elsif %w(TrueClass FalseClass Boolean).include? klass
      :boolean
    elsif ['BigDecimal'].include? klass
      :decimal
    else
      :record
    end
  end

  def self.[](name)
    get(name).value
  end

  def self.get(name)
    name = name.to_s
    preference = Preference.find_by(name: name)
    if preference.nil? && reference.key?(name)
      preference = new
      preference.name = name
      preference.nature = reference[name][:nature]
      preference.value = reference[name][:default] if reference[name][:default]
      preference.save!
    elsif preference.nil?
      fail ArgumentError, "Undefined preference: #{name}"
    end
    preference
  end

  def self.get!(name, default_value = nil, nature = :string)
    name = name.to_s
    preference = Preference.find_by(name: name)
    if preference.nil? && reference.key?(name)
      preference = new name: name, nature: reference[name][:nature]
      preference.value = default_value || reference[name][:default]
      preference.save!
    elsif preference.nil?
      preference = new name: name, nature: nature
      preference.value = default_value
      preference.save!
    end
    preference
  end

  def self.set!(name, value, nature = :string)
    name = name.to_s
    preference = Preference.find_by(name: name)
    if preference.nil? && reference.key?(name)
      preference = new name: name, nature: reference[name][:nature]
    elsif preference.nil?
      preference = new name: name, nature: nature
    end
    preference.value = value
    preference.save!
    preference
  end

  def value
    send(nature + '_value')
  end

  def value=(object)
    #     if @@reference[self.name]
    #       self.nature = @@reference[self.name][:nature]
    #       self.record_value_type = @@reference[self.name][:model].name if @@reference[self.name][:model]
    #     end
    self.nature ||= self.class.type_to_nature(object)
    unless @@natures.include? self.nature
      fail ArgumentError, "Object to define as preference is an unknown type #{object.class.name}:#{self.nature}"
    end
    if self.nature == 'record' && object.class.name != record_value_type
      begin
        send(self.nature.to_s + '_value=', record_value_type.constantize.find(object.to_i))
      rescue
        self.record_value_id = nil
      end
    else
      send(self[:nature].to_s + '_value=', object)
    end
  end

  def set(object)
    self.value = object
    save
  end

  def set!(object)
    self.value = object
    self.save!
  end

  def human_name(locale = nil)
    "preferences.#{name}".t(locale: locale)
  end
  alias_method :label, :human_name

  def record?
    self.nature == 'record'
  end

  def model
    self.record? ? record_value_type.constantize : nil
  end

  private

  def self.convert(nature, string)
    case nature.to_sym
    when :boolean
      (string == 'true' ? true : false)
    when :integer
      string.to_i
    when :decimal
      string.to_f
    else
      string
    end
  end
end
