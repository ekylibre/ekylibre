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
# == Table: outgoing_payment_modes
#
#  active          :boolean          default(FALSE), not null
#  cash_id         :integer
#  created_at      :datetime         not null
#  creator_id      :integer
#  id              :integer          not null, primary key
#  lock_version    :integer          default(0), not null
#  name            :string           not null
#  position        :integer
#  sepa            :boolean          default(FALSE), not null
#  updated_at      :datetime         not null
#  updater_id      :integer
#  with_accounting :boolean          default(FALSE), not null
#

class OutgoingPaymentMode < Ekylibre::Record::Base
  acts_as_list
  belongs_to :cash
  has_many :payments, class_name: 'OutgoingPayment', foreign_key: :mode_id, inverse_of: :mode, dependent: :restrict_with_error
  has_many :payment_lists, class_name: 'OutgoingPaymentList', foreign_key: :mode_id, inverse_of: :mode, dependent: :restrict_with_error
  has_many :supplier_payment_modes, class_name: 'Entity', foreign_key: :supplier_payment_mode_id, inverse_of: :supplier_payment_mode, dependent: :restrict_with_error
  # [VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates :active, :sepa, :with_accounting, inclusion: { in: [true, false] }
  validates :name, presence: true, length: { maximum: 500 }
  # ]VALIDATORS]
  validates :name, length: { allow_nil: true, maximum: 50 }
  validates :cash, presence: true

  validate :bank_details_for_sepa

  delegate :currency, to: :cash

  scope :matching_cash, ->(id) { where(cash_id: id) }

  protect(on: :destroy) do
    payments.any? || supplier_payment_modes.any?
  end

  scope :mode_sepa, -> { where(sepa: true) }
  scope :active, -> { where(active: true) }

  def self.load_defaults(**_options)
    %w[cash check transfer].each do |nature|
      cash_nature = nature == 'cash' ? :cash_box : :bank_account
      cash = Cash.find_by(nature: cash_nature)
      next unless cash
      create!(
        name: OutgoingPaymentMode.tc("default.#{nature}.name"),
        with_accounting: true,
        cash: cash
      )
    end
  end

  private

  def bank_details_for_sepa
    if sepa && (cash.bank_account_holder_name.blank? || cash.iban.blank?)
      errors.add(:sepa, :missing_bank_details_for_sepa)
    end
  end
end
