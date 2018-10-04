# = Informations
#
# == License
#
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2009 Brice Texier, Thibaud Merigon
# Copyright (C) 2010-2012 Brice Texier
# Copyright (C) 2012-2018 Brice Texier, David Joulin
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
  enumerize :nature, in: %i[accounting_system country currency boolean
                            decimal language integer record
                            spatial_reference_system string], predicates: true
  @@conversions = { float: :decimal, true_class: :boolean, false_class: :boolean, fixnum: :integer }
  cattr_reader :reference
  attr_readonly :user_id, :name, :nature
  belongs_to :user, class_name: 'Entity'
  belongs_to :record_value, polymorphic: true
  # cattr_reader :reference
  # [VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates :boolean_value, inclusion: { in: [true, false] }, allow_blank: true
  validates :decimal_value, numericality: { greater_than: -1_000_000_000_000_000, less_than: 1_000_000_000_000_000 }, allow_blank: true
  validates :integer_value, numericality: { only_integer: true, greater_than: -2_147_483_649, less_than: 2_147_483_648 }, allow_blank: true
  validates :name, presence: true, length: { maximum: 500 }
  validates :nature, presence: true
  validates :record_value_type, length: { maximum: 500 }, allow_blank: true
  validates :string_value, length: { maximum: 500_000 }, allow_blank: true
  # ]VALIDATORS]
  validates :nature, length: { allow_nil: true, maximum: 60 }
  validates :nature, inclusion: { in: nature.values }
  validates :name, uniqueness: { scope: [:user_id] }

  self.lock_optimistically = false

  alias_attribute :accounting_system_value, :string_value
  alias_attribute :country_value, :string_value
  alias_attribute :currency_value, :string_value
  alias_attribute :language_value, :string_value
  alias_attribute :spatial_reference_system_value, :string_value

  scope :global, -> { where(name: @@reference.keys.map(&:to_s), user_id: nil) }

  before_validation do
    if record? && record_value
      self.record_value_type = record_value.class.base_class.name
    end
  end

  class << self
    def prefer(name, nature, default_value = nil)
      @@reference ||= HashWithIndifferentAccess.new
      unless self.nature.values.include?(nature.to_s)
        raise ArgumentError, "Nature (#{nature.inspect}) is unacceptable. #{self.nature.values.to_sentence} are accepted."
      end
      @@reference[name] = { name: name, nature: nature.to_sym, default: default_value }
    end

    def check!
      reference.keys.each do |pref|
        get(pref)
      end
    end

    def type_to_nature(object)
      klass = object.class.to_s
      if object.is_a?(Nomen::Item) && nature = object.nomenclature.name.to_s.singularize.to_sym && nature.values.include?(nature)
        nature
      elsif %w[String Symbol NilClass].include? klass
        :string
      elsif %w[Integer Fixnum Bignum].include? klass
        :integer
      elsif %w[TrueClass FalseClass Boolean].include? klass
        :boolean
      elsif ['BigDecimal'].include? klass
        :decimal
      else
        :record
      end
    end

    def [](name)
      get!(name).value
    end

    # Raise an exception if preference cannot be found or initialized
    # with the reference
    def get!(name)
      name = name.to_s
      preference = Preference.find_by(name: name)
      unless preference
        if reference.key?(name)
          preference = new(name: name, nature: reference[name][:nature])
          preference.value = reference[name][:default] if reference[name][:default]
          preference.save!
        else
          raise ArgumentError, "Undefined preference: #{name}"
        end
      end
      preference
    end

    # Try to find preference and create it with default value only
    # if it doesn't exist
    def get(name, default_value = nil, nature = nil)
      name = name.to_s
      preference = Preference.find_by(name: name)
      unless preference
        attributes = { name: name, nature: nature, value: default_value }
        if reference.key?(name)
          attributes[:nature] = reference[name][:nature]
          attributes[:value] ||= reference[name][:default]
        end
        preference = create!(attributes)
      end
      preference
    end

    # Returns value of the given preference
    def value(name, default_value = nil, nature = nil)
      get(name, default_value, nature).value
    end

    # Find and set preference with given value
    def set!(name, value, nature = nil)
      name = name.to_s

      preference_ids = Preference.where(name: name).order(:id).offset(1).pluck(:id)
      Preference.where(id: preference_ids).delete_all if preference_ids.any?

      preference = Preference.find_by(name: name)
      if preference
        preference.reload
      else
        attributes = { name: name, nature: nature }
        attributes[:nature] = reference[name][:nature] if reference.key?(name)
        preference = new(attributes)
      end
      preference.value = value
      preference.save!
      preference
    end
  end

  prefer :entry_autocompletion, :boolean, true
  prefer :bookkeep_automatically, :boolean, true
  prefer :permanent_stock_inventory, :boolean, true
  prefer :unbilled_payables, :boolean, false
  prefer :bookkeep_in_draft, :boolean, true
  prefer :detail_payments_in_deposit_bookkeeping, :boolean, true
  prefer :use_global_search, :boolean, false
  prefer :use_entity_codes_for_account_numbers, :boolean, true
  prefer :sales_conditions, :string, ''
  prefer :accounting_system, :accounting_system, Nomen::AccountingSystem.default("fr_pcga")
  prefer :language, :language, Nomen::Language.default
  prefer :country,  :country, Nomen::Country.default
  prefer :currency, :currency, Nomen::Currency.default
  prefer :map_measure_srs, :spatial_reference_system, Nomen::SpatialReferenceSystem.default
  prefer :create_activities_from_telepac, :boolean, false
  prefer :catalog_price_item_addition_if_blank, :boolean, true
  prefer :client_account_radix, :string, ''
  prefer :supplier_account_radix, :string, ''
  prefer :employee_account_radix, :string, ''
  prefer :account_number_digits, :integer, 8
  # TODO: manage period as list selector
  prefer :default_depreciation_period, :string, 'yearly'

  prefer :distribute_sales_and_purchases_on_activities, :boolean, false
  prefer :distribute_sales_and_purchases_on_teams, :boolean, false

  # DEPRECATED PREFERENCES
  prefer :host, :string, 'erp.example.com'

  # Returns the name of the column used to store preference data
  def value_attribute
    nature + '_value'
  end

  # Returns basically the value of the preference
  def value
    send(value_attribute)
  end

  def value=(object)
    self.nature ||= self.class.type_to_nature(object)
    send(value_attribute + '=', object)
  end

  def set(object)
    self.value = object
    save
  end

  def set!(object)
    reload if already_updated?
    self.value = object
    save!
  end

  def human_name(locale = nil)
    "preferences.#{name}".t(locale: locale)
  end
  alias label human_name

  def model
    record? ? record_value_type.constantize : nil
  end
end
