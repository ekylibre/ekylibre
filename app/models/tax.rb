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
# == Table: taxes
#
#  active                            :boolean          default(FALSE), not null
#  amount                            :decimal(19, 4)   default(0.0), not null
#  collect_account_id                :integer
#  country                           :string           not null
#  created_at                        :datetime         not null
#  creator_id                        :integer
#  deduction_account_id              :integer
#  description                       :text
#  fixed_asset_collect_account_id    :integer
#  fixed_asset_deduction_account_id  :integer
#  id                                :integer          not null, primary key
#  intracommunity                    :boolean          default(FALSE), not null
#  intracommunity_payable_account_id :integer
#  lock_version                      :integer          default(0), not null
#  name                              :string           not null
#  nature                            :string           not null
#  reference_name                    :string
#  updated_at                        :datetime         not null
#  updater_id                        :integer
#

class Tax < Ekylibre::Record::Base
  refers_to :country
  refers_to :nature, class_name: 'TaxNature'
  refers_to :reference_name, class_name: 'Tax'
  belongs_to :collect_account, class_name: 'Account'
  belongs_to :deduction_account, class_name: 'Account'
  belongs_to :fixed_asset_collect_account, class_name: 'Account'
  belongs_to :fixed_asset_deduction_account, class_name: 'Account'
  belongs_to :intracommunity_payable_account, class_name: 'Account'
  has_many :product_nature_category_taxations, dependent: :restrict_with_error
  has_many :purchase_items
  has_many :sale_items
  has_many :journal_entry_items
  has_many :tax_declaration_items
  # [VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates :active, :intracommunity, inclusion: { in: [true, false] }
  validates :amount, presence: true, numericality: { greater_than: -1_000_000_000_000_000, less_than: 1_000_000_000_000_000 }
  validates :country, :nature, presence: true
  validates :description, length: { maximum: 500_000 }, allow_blank: true
  validates :name, presence: true, length: { maximum: 500 }
  # ]VALIDATORS]
  validates :reference_name, length: { allow_nil: true, maximum: 120 }
  validates :collect_account, :deduction_account, presence: true
  validates :name, uniqueness: true
  # validates :amount, uniqueness: { scope: [:country, :nature] }
  validates :amount, numericality: { in: 0..100 }
  validates :intracommunity_payable_account, presence: { if: :intracommunity }
  delegate :name, to: :collect_account, prefix: true
  delegate :name, to: :deduction_account, prefix: true
  # selects_among_all :used_for_untaxed_deals, if: :null_amount?

  scope :current, -> { where(active: true).order(:country, :amount) }

  before_validation do
    if Nomen::TaxNature.find(nature)
      self.name = short_label if name.blank?
    end
    self.active = false if active.nil?
    true
  end

  protect(on: :destroy) do
    product_nature_category_taxations.any? || sale_items.any? || purchase_items.any? ||
      tax_declaration_items.any? || journal_entry_items.any?
  end

  class << self
    def used_for_untaxed_deals
      where(amount: 0).reorder(:id).first
    end

    # Returns TaxNature items which are used by recorded taxes
    def available_natures
      Nomen::TaxNature.select do |item|
        references = Nomen::Tax.list.keep_if { |tax| tax.nature.to_s == item.name.to_s }
        taxes = Tax.where(reference_name: references.map(&:name))
        taxes.any?
      end
    end

    def clean!
      Tax.find_each do |tax|
        tax.destroy if tax.destroyable?
      end
    end

    # Find a tax at the given date. Conditions can be given to filter on
    # `country`, `nature`, and `amount`. `nature` is a name of a tax nature (See
    # `tax_natures` nomenclature.
    def find_on(wanted_on, conditions = {})
      name = nil
      Nomen::Tax.where(conditions).find_each do |item|
        if item.started_on <= wanted_on &&
           (item.stopped_on.blank? ||
            wanted_on <= item.stopped_on)
          name = item.name
          break
        end
      end
      return nil if name.blank?
      Tax.import_from_nomenclature(name)
    end

    # Load a tax from tax nomenclature
    def import_from_nomenclature(reference_name, active = nil)
      unless item = Nomen::Tax.find(reference_name)
        raise ArgumentError, "The tax #{reference_name.inspect} is not known"
      end
      tax = Tax.find_by(amount: item.amount, nature: item.nature, country: item.country)
      tax ||= Tax.find_by(reference_name: reference_name)

      if tax
        tax.update_column(:active, active) unless active.nil?
        return tax
      end
      nature = Nomen::TaxNature.find(item.nature)
      if nature.computation_method != :percentage
        raise StandardError, 'Can import only percentage computed taxes'
      end
      attributes = {
        amount: item.amount,
        name: item.human_name,
        nature: item.nature,
        country: item.country,
        active: (active.nil? ? true : active),
        reference_name: item.name
      }
      %i[deduction collect fixed_asset_deduction fixed_asset_collect].each do |account|
        next unless name = nature.send("#{account}_account")
        tax_radical = Account.find_or_import_from_nomenclature(name)
        # find if already account tax  by number was created
        tax_account = Account.find_or_create_by_number("#{tax_radical.number[0..tax_radical.number.length - 2]}#{nature.suffix}")
        tax_account.name = item.human_name
        tax_account.usages = tax_radical.usages
        tax_account.save!

        attributes["#{account}_account_id"] = tax_account.id
      end
      Tax.create!(attributes)
    end

    # Load all tax from tax nomenclature by country
    def import_all_from_nomenclature(options = {})
      country = options[:country] || Preference[:country]
      today = Time.zone.today
      Nomen::Tax.where(country: country.to_sym).find_each do |tax|
        if options[:active]
          if tax.started_on
            next unless today > tax.started_on
          end
          if tax.stopped_on
            next unless today < tax.stopped_on
          end
        end
        import_from_nomenclature(tax.name, true)
      end
    end

    # Load default taxes of instance country
    def load_defaults
      import_all_from_nomenclature(country: Preference[:country].to_sym, active: true)
    end
  end

  # Compute the tax amount
  # If +with_taxes+ is true, it's considered that the given amount
  # is an amount with tax
  def compute(amount, *args)
    options = args.extract_options!
    all_taxes_included = args.shift || options[:all_taxes_included] || false
    percentage = (options[:intracommunity] ? self.amount : usable_amount).to_d / 100
    if all_taxes_included
      amount.to_d * percentage / (1 + percentage)
    else
      amount.to_d * percentage
    end
  end

  # Returns the intracommunity tax amount used in purchase reverse-charge
  def intracommunity_amount_of(pretax_amount)
    pretax_amount + compute(pretax_amount, intracommunity: true)
  end

  # Returns the pretax amount of an amount
  def pretax_amount_of(with_tax_amount)
    (with_tax_amount.to_d / coefficient)
  end

  # Returns the amount of a pretax amount
  def amount_of(pretax_amount)
    (pretax_amount.to_d * coefficient)
  end

  # Returns true if amount is equal to 0
  def null_amount?
    amount.zero?
  end

  # Returns the matching coefficient k of the percentage
  # where pretax_amount * k = amount_with_tax
  def coefficient
    (100 + usable_amount) / 100
  end

  # Returns a usable amount for sale and purchase i.e. amount when tax is not
  # selected as intracommunity tax
  def usable_amount
    intracommunity ? 0 : amount
  end

  # Returns the short label of a tax
  def short_label
    "#{amount.l(precision: 0)}% (#{country}) #{nature.l}"
  end
end
