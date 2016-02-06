# = Informations
#
# == License
#
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2009 Brice Texier, Thibaud Merigon
# Copyright (C) 2010-2012 Brice Texier
# Copyright (C) 2012-2016 Brice Texier, David Joulin
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
#  amount               :decimal(19, 4)   default(0.0), not null
#  collect_account_id   :integer
#  created_at           :datetime         not null
#  creator_id           :integer
#  deduction_account_id :integer
#  description          :text
#  id                   :integer          not null, primary key
#  lock_version         :integer          default(0), not null
#  name                 :string           not null
#  reference_name       :string
#  updated_at           :datetime         not null
#  updater_id           :integer
#

class Tax < Ekylibre::Record::Base
  attr_readonly :amount
  refers_to :reference_name, class_name: 'Tax'
  belongs_to :collect_account, class_name: 'Account'
  belongs_to :deduction_account, class_name: 'Account'
  has_many :product_nature_category_taxations, dependent: :restrict_with_error
  has_many :purchase_items
  has_many :sale_items
  # [VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_numericality_of :amount, allow_nil: true
  validates_presence_of :amount, :name
  # ]VALIDATORS]
  validates_length_of :reference_name, allow_nil: true, maximum: 120
  validates_presence_of :collect_account
  validates_presence_of :deduction_account
  validates_uniqueness_of :name
  validates_numericality_of :amount, in: 0..100

  delegate :name, to: :collect_account, prefix: true
  delegate :name, to: :deduction_account, prefix: true
  # selects_among_all :used_for_untaxed_deals, if: :null_amount?

  class << self
    def used_for_untaxed_deals
      where(amount: 0).reorder(:id).first
    end

    # Returns TaxNature items which are used by recorded taxes
    def available_natures
      Nomen::TaxNature.list.select do |item|
        references = Nomen::Tax.list.keep_if { |tax| tax.nature.to_s == item.name.to_s }
        taxes = Tax.where(reference_name: references.map(&:name))
        taxes.any?
      end
    end

    # Load a tax from tax nomenclature
    def import_from_nomenclature(reference_name)
      unless item = Nomen::Tax.find(reference_name)
        raise ArgumentError, "The tax #{reference_name.inspect} is not known"
      end
      unless tax = Tax.find_by_reference_name(reference_name)
        nature = Nomen::TaxNature.find(item.nature)
        if nature.computation_method != :percentage
          raise StandardError, 'Can import only percentage computed taxes'
        end
        attributes = {
          amount: item.amount,
          name: item.human_name,
          reference_name: item.name
        }
        for account in [:deduction, :collect]
          next unless name = nature.send("#{account}_account")
          tax_radical = Account.find_or_import_from_nomenclature(name)
          # find if already account tax  by number was created
          tax_account = Account.find_or_create_by!(number: "#{tax_radical.number}#{nature.suffix}") do |a|
            a.name = "#{tax_radical.name} - #{item.human_name}"
            a.usages = tax_radical.usages
          end
          attributes["#{account}_account_id"] = tax_account.id
        end
        tax = create!(attributes)
      end
      tax
    end

    # Load all tax from tax nomenclature by country
    def import_all_from_nomenclature(country)
      Nomen::Tax.where(country: country).find_each do |tax|
        import_from_nomenclature(tax.name)
      end
    end

    # Load default taxes of instance country
    def load_defaults
      import_all_from_nomenclature(Preference[:country].to_sym)
    end

    # find tax reference name with no stopped_at AKA current reference taxes
    # FIXME: Invalid way to find current tax. Need to normalize tax use when no references
    def current
      ids = []
      Tax.find_each do |tax|
        if item = Nomen::Tax.find(tax.reference_name)
          ids << tax.id unless item.stopped_on
        else
          ids << tax.id
        end
      end
      Tax.where(id: ids).order(:amount)
    end
  end

  protect(on: :destroy) do
    product_nature_category_taxations.any? || sale_items.any? || purchase_items.any?
  end

  # Compute the tax amount
  # If +with_taxes+ is true, it's considered that the given amount
  # is an amount with tax
  def compute(amount, all_taxes_included = false)
    if all_taxes_included
      amount.to_d / (1 + 100 / self.amount.to_d)
    else
      amount.to_d * self.amount.to_d / 100
    end
  end

  # Returns the pretax amount of an amount
  def pretax_amount_of(amount)
    (amount.to_d / coefficient)
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
    (100 + amount) / 100
  end

  # Returns the short label of a tax
  def short_label
    label = "#{amount}%"
    if reference = Nomen::Tax[reference_name]
      label << " (#{reference.country})"
    end
    label
  end
end
