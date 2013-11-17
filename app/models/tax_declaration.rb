# = Informations
#
# == License
#
# Ekylibre - Simple ERP
# Copyright (C) 2009-2013 Brice Texier, Thibaud Merigon
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
# == Table: tax_declarations
#
#  accounted_at             :datetime
#  acquisition_amount       :decimal(19, 4)
#  address                  :string(255)
#  amount                   :decimal(19, 4)
#  assimilated_taxes_amount :decimal(19, 4)
#  balance_amount           :decimal(19, 4)
#  collected_amount         :decimal(19, 4)
#  created_at               :datetime         not null
#  creator_id               :integer
#  declared_on              :date
#  deferred_payment         :boolean
#  financial_year_id        :integer
#  id                       :integer          not null, primary key
#  journal_entry_id         :integer
#  lock_version             :integer          default(0), not null
#  nature                   :string(255)      default("normal"), not null
#  paid_amount              :decimal(19, 4)
#  paid_on                  :date
#  started_on               :date
#  stopped_on               :date
#  updated_at               :datetime         not null
#  updater_id               :integer
#


class TaxDeclaration < Ekylibre::Record::Base
  # attr_accessible :address, :started_on, :stopped_on
  belongs_to :financial_year
  #[VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_numericality_of :acquisition_amount, :amount, :assimilated_taxes_amount, :balance_amount, :collected_amount, :paid_amount, allow_nil: true
  validates_length_of :address, :nature, allow_nil: true, maximum: 255
  validates_presence_of :nature
  #]VALIDATORS]


  NB_DAYS_MONTH=30.42

  # this method:allows to verify the different characteristics of the tax declaration.
  validate do
    errors.add(:stopped_on, :one_data_to_record_tax_declaration)  if self.collected_amount.zero? and self.acquisition_amount.zero? and self.assimilated_taxes_amount.zero? and self.paid_amount.zero? and self.balance_amount.zero?
    errors.add(:started_on, :overlapped_period_declaration) if TaxDeclaration.where("? BETWEEN started_on AND stopped_on", self.started_on).first
    errors.add(:stopped_on, :overlapped_period_declaration) if TaxDeclaration.where("? BETWEEN started_on AND stopped_on", self.started_on).first
    unless self.financial_year.nil?
      errors.add(:declared_on, :declaration_date_after_period) if self.declared_on < self.financial_year.stopped_on
    end
  end

  # this method:allows to comptabilize the tax declaration after it creation.
  bookkeep(on: :nothing) do |b|
  end

end
