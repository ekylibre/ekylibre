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
# == Table: cash_transfers
#
#  accounted_at               :datetime
#  created_at                 :datetime         not null
#  creator_id                 :integer(4)
#  currency_rate              :decimal(19, 10)  not null
#  custom_fields              :jsonb
#  description                :text
#  emission_amount            :decimal(19, 4)   not null
#  emission_cash_id           :integer(4)       not null
#  emission_currency          :string           not null
#  emission_journal_entry_id  :integer(4)
#  id                         :integer(4)       not null, primary key
#  lock_version               :integer(4)       default(0), not null
#  number                     :string           not null
#  reception_amount           :decimal(19, 4)   not null
#  reception_cash_id          :integer(4)       not null
#  reception_currency         :string           not null
#  reception_journal_entry_id :integer(4)
#  transfered_at              :datetime         not null
#  updated_at                 :datetime         not null
#  updater_id                 :integer(4)
#

require 'test_helper'

class CashTransferTest < Ekylibre::Testing::ApplicationTestCase::WithFixtures
  test_model_actions

  # Le taux de change vient des taux de référence de la BCE, donc du réseau.
  # La source est remplacée ici : ces tests ne sortent pas.
  setup do
    @rates_source = I18n::Complements::Numisma.rates_source
    I18n::Complements::Numisma.rates_source = -> { { 'USD' => 1.16 } }
    I18n::Complements::Numisma.reset_rates!
  end

  teardown do
    I18n::Complements::Numisma.rates_source = @rates_source
    I18n::Complements::Numisma.reset_rates!
  end

  def build_transfer(attributes = {})
    transfer = CashTransfer.new({ emission_amount: 100, transfered_at: Time.zone.now }.merge(attributes))
    transfer.emission_currency = 'EUR'
    transfer.reception_currency = 'USD'
    transfer
  end

  test 'the currency rate is fetched when it is not given' do
    transfer = build_transfer
    transfer.valid?

    assert_equal 1.16, transfer.currency_rate
    assert_equal 116, transfer.reception_amount
    assert_empty transfer.errors.details[:currency_rate]
  end

  test 'an identical currency needs no rate lookup' do
    transfer = build_transfer
    transfer.reception_currency = 'EUR'
    transfer.valid?

    assert_equal 1, transfer.currency_rate
  end

  # Le taux étant cherché depuis une validation, une source injoignable
  # produisait une 500 à l'enregistrement. Elle doit donner une erreur de
  # validation, puisque l'utilisateur peut saisir le taux lui-même.
  test 'an unreachable rate source becomes a validation error' do
    I18n::Complements::Numisma.rates_source = -> { raise SocketError.new('injoignable') }
    I18n::Complements::Numisma.reset_rates!

    transfer = build_transfer
    assert_nothing_raised { transfer.valid? }

    assert_equal [:currency_rate_unavailable], transfer.errors.details[:currency_rate].map { |d| d[:error] },
                 'le « ne peut pas être vide » doit être remplacé par la cause réelle'
    assert_includes transfer.errors.full_messages_for(:currency_rate).first, 'EUR'
  end

  test 'a hand-entered rate is used even when the source is unreachable' do
    I18n::Complements::Numisma.rates_source = -> { raise SocketError.new('injoignable') }
    I18n::Complements::Numisma.reset_rates!

    transfer = build_transfer(currency_rate: 1.09)
    transfer.valid?

    assert_empty transfer.errors.details[:currency_rate]
    assert_equal 109, transfer.reception_amount
  end

  # Le drapeau qui porte l'indisponibilité est une variable d'instance : il doit
  # être remis à zéro à chaque validation, sans quoi l'erreur resterait affichée
  # après que l'utilisateur a saisi un taux.
  test 'the unavailability does not persist across validations' do
    I18n::Complements::Numisma.rates_source = -> { raise SocketError.new('injoignable') }
    I18n::Complements::Numisma.reset_rates!

    transfer = build_transfer
    transfer.valid?
    refute_empty transfer.errors.details[:currency_rate]

    transfer.currency_rate = 1.09
    transfer.valid?
    assert_empty transfer.errors.details[:currency_rate]
  end
end
