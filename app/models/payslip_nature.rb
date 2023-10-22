# frozen_string_literal: true

# = Informations
#
# == License
#
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2009 Brice Texier, Thibaud Merigon
# Copyright (C) 2010-2012 Brice Texier
# Copyright (C) 2012-2014 Brice Texier, David Joulin
# Copyright (C) 2015-2023 Ekylibre SAS
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
# == Table: payslip_natures
#
#  account_id      :integer(4)
#  active          :boolean          default(FALSE), not null
#  by_default      :boolean          default(FALSE), not null
#  created_at      :datetime         not null
#  creator_id      :integer(4)
#  currency        :string           not null
#  id              :integer(4)       not null, primary key
#  journal_id      :integer(4)       not null
#  lock_version    :integer(4)       default(0), not null
#  name            :string           not null
#  updated_at      :datetime         not null
#  updater_id      :integer(4)
#  with_accounting :boolean          default(FALSE), not null
#

class PayslipNature < ApplicationRecord
  refers_to :currency
  belongs_to :account
  belongs_to :journal
  has_many :payslips, foreign_key: :nature_id, dependent: :restrict_with_exception
  # [VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates :active, :by_default, :with_accounting, :imported_centralizing_entries, inclusion: { in: [true, false] }
  validates :currency, :journal, presence: true
  validates :name, presence: true, uniqueness: true, length: { maximum: 500 }
  # ]VALIDATORS]
  validates :currency, match: { with: :journal }

  selects_among_all

  scope :actives, -> { where(active: true) }

  after_initialize if: :new_record? do
    self.active ||= true
    self.with_accounting ||= false
    self.imported_centralizing_entries ||= false
  end

  before_validation do
    self.currency ||= Preference[:currency]
    self.active ||= true
    self.with_accounting ||= false
    self.imported_centralizing_entries ||= false
    self.journal ||= Journal.create!(name: "enumerize.journal.nature.payslip".t,
                                  nature: 'payslip', currency: Preference[:currency],
                                  closed_on: Date.new(1899, 12, 31).end_of_month)
    if with_accounting && imported_centralizing_entries
      self.account ||= Account.find_or_import_from_nomenclature(:staff_due_remunerations)
    elsif with_accounting
      self.account ||= Account.find_or_import_from_nomenclature(:staff_expenses)
    end
  end

  protect on: :destroy do
    payslips.any?
  end

  class << self
    # Load default payslip nature
    def load_defaults(**_options)
      nature = :payslip
      currency = Preference[:currency]
      journal = Journal.find_by(nature: nature, currency: currency)
      journal ||= Journal.create!(name: "enumerize.journal.nature.#{nature}".t,
                                  nature: nature.to_s, currency: currency,
                                  closed_on: Date.new(1899, 12, 31).end_of_month)
      unless find_by(name: PayslipNature.tc('default.name'))
        create!(
          name: PayslipNature.tc('default.name'),
          active: true,
          with_accounting: false,
          imported_centralizing_entries: false,
          journal: journal
        )
      end
    end
  end
end
