# = Informations
#
# == License
#
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2009 Brice Texier, Thibaud Merigon
# Copyright (C) 2010-2012 Brice Texier
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
# == Table: taxes
#
#  amount               :decimal(19, 4)   default(0.0), not null
#  collect_account_id   :integer
#  computation_method   :string(20)       not null
#  created_at           :datetime         not null
#  creator_id           :integer
#  deduction_account_id :integer
#  description          :text
#  id                   :integer          not null, primary key
#  included             :boolean          not null
#  lock_version         :integer          default(0), not null
#  name                 :string(255)      not null
#  reductible           :boolean          default(TRUE), not null
#  reference_name       :string(120)
#  updated_at           :datetime         not null
#  updater_id           :integer
#


class Tax < Ekylibre::Record::Base
  attr_readonly :computation_method, :amount
  enumerize :reference_name, in: Nomen::Taxes.all
  enumerize :computation_method, in: [:amount, :percentage], default: :percentage, predicates: true
  belongs_to :collect_account, class_name: "Account"
  belongs_to :deduction_account, class_name: "Account"
  has_many :product_nature_category_taxations, dependent: :restrict_with_error
  has_many :purchase_items
  has_many :sale_items
  #[VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_numericality_of :amount, allow_nil: true
  validates_length_of :computation_method, allow_nil: true, maximum: 20
  validates_length_of :reference_name, allow_nil: true, maximum: 120
  validates_length_of :name, allow_nil: true, maximum: 255
  validates_inclusion_of :included, :reductible, in: [true, false]
  validates_presence_of :amount, :computation_method, :name
  #]VALIDATORS]
  validates_inclusion_of :computation_method, in: self.computation_method.values
  validates_presence_of :collect_account
  validates_presence_of :deduction_account
  validates_uniqueness_of :name
  validates_numericality_of :amount, in: 0..100, if: :percentage?

  # selects_among_all :used_for_untaxed_deals, if: :null_amount?

  def self.used_for_untaxed_deals
    self.where(amount: 0).reorder(:id).first
  end

  scope :percentages, -> { where(:computation_method => 'percentage') }

  protect(on: :destroy) do
    self.product_nature_category_taxations.any? or self.sale_items.any? or self.purchase_items.any?
  end

  # Compute the tax amount
  # If +with_taxes+ is true, it's considered that the given amount
  # is an amount with tax
  def compute(amount, all_tax_included = false)
    if self.percentage? and all_tax_included
      amount.to_d / (1 + 100/self.amount.to_d)
    elsif self.percentage?
      amount.to_d * self.amount.to_d/100
    elsif self.amount?
      self.amount
    end
  end

  # Returns the pretax amount of an amount
  def pretax_amount_of(amount)
    return (self.percentage? ? (amount.to_d / coefficient) : (amount.to_d - self.amount.to_d))
  end

  # Returns the amount of a pretax amount
  def amount_of(pretax_amount)
    return (self.percentage? ? (pretax_amount.to_d * coefficient) : (pretax_amount.to_d + self.amount.to_d))
  end

  # Returns true if amount is equal to 0
  def null_amount?
    self.amount.zero?
  end

  # Returns the matching coefficient k of the percentage
  # where pretax_amount * k = amount_with_tax
  def coefficient
    raise StandardError("Can only use coefficient method with percentage taxes") unless self.percentage?
    return (1.0 + 0.01*self.amount.to_d)
  end

  # Load a tax from tax nomenclature
  def self.import_from_nomenclature(reference_name)
    unless item = Nomen::Taxes.find(reference_name)
      raise ArgumentError, "The tax #{reference_name.inspect} is not known"
    end
    unless tax = Tax.find_by_reference_name(reference_name)
      attributes = {
        :computation_method => item.computation_method,
        :amount => item.amount,
        :name => item.human_name,
        :reference_name => item.name
      }
      for account in [:deduction, :collect]
        if name = item.send("#{account}_account")
          # find the relative account tax  by name
          tax_radical = Account.find_or_create_in_chart(name)
          # find if already account tax  by number was created
          tax_account = Account.find_or_create_by!(:number => tax_radical.number + item.suffix.to_s) do |a|
            a.name = tax_radical.name + " - " + item.human_name
            a.usages = tax_radical.usages
          end
          attributes["#{account}_account_id"] = tax_account.id
        end
      end
      tax = self.create!(attributes)
    end
    return tax
  end

  # Load.all tax from tax nomenclature by country
  def self.import_all_from_nomenclature(country = Preference[:country])
    for tax in Nomen::Taxes.items.values.select{|i| i.country == country}
      import_from_nomenclature(tax.name)
    end
  end

end
