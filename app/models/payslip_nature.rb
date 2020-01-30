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
# == Table: payslip_natures
#
#  account_id      :integer
#  active          :boolean          default(FALSE), not null
#  by_default      :boolean          default(FALSE), not null
#  created_at      :datetime         not null
#  creator_id      :integer
#  currency        :string           not null
#  id              :integer          not null, primary key
#  journal_id      :integer          not null
#  lock_version    :integer          default(0), not null
#  name            :string           not null
#  updated_at      :datetime         not null
#  updater_id      :integer
#  with_accounting :boolean          default(FALSE), not null
#

class PayslipNature < Ekylibre::Record::Base
  refers_to :currency
  belongs_to :account
  belongs_to :journal
  has_many :payslips, foreign_key: :nature_id, dependent: :restrict_with_exception

  # [VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates :active, :by_default, :with_accounting, inclusion: { in: [true, false] }
  validates :currency, :journal, presence: true
  validates :name, presence: true, uniqueness: true, length: { maximum: 500 }
  # ]VALIDATORS]
  validates :currency, match: { with: :journal }

  selects_among_all

  after_initialize if: :new_record? do
    self.active = true
    self.with_accounting = true
  end

  protect on: :destroy do
    payslips.any?
  end
end
