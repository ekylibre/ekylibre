# = Informations
#
# == License
#
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2009 Brice Texier, Thibaud Merigon
# Copyright (C) 2010-2012 Brice Texier
# Copyright (C) 2012-2017 Brice Texier, David Joulin
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
# == Table: journals
#
#  accountant_id                      :integer
#  closed_on                          :date             not null
#  code                               :string           not null
#  created_at                         :datetime         not null
#  creator_id                         :integer
#  currency                           :string           not null
#  custom_fields                      :jsonb
#  id                                 :integer          not null, primary key
#  lock_version                       :integer          default(0), not null
#  name                               :string           not null
#  nature                             :string           not null
#  updated_at                         :datetime         not null
#  updater_id                         :integer
#  used_for_affairs                   :boolean          default(FALSE), not null
#  used_for_gaps                      :boolean          default(FALSE), not null
#  used_for_permanent_stock_inventory :boolean          default(FALSE), not null
#  used_for_tax_declarations          :boolean          default(FALSE), not null
#  used_for_unbilled_payables         :boolean          default(FALSE), not null
#

require 'test_helper'

class JournalTest < ActiveSupport::TestCase
  test_model_actions
  test 'presence of nature scopes' do
    for nature in Journal.nature.values
      scope_name = nature.to_s.pluralize.to_sym
      assert Journal.respond_to?(scope_name), "Journal must have a scope #{scope_name}"
      # TODO: Check that scope works
    end
  end
  test 'accountant can be set on various journals' do
    various_journal = journals(:journals_001)
    various_journal.accountant = entities(:entities_016)
    assert various_journal.valid?
  end
  test 'set accountant close all entries' do
    various_journal = journals(:journals_001)
    various_journal.accountant = entities(:entities_016)
    assert various_journal.entries.any? { |e| e.draft? || e.confirmed? }
    assert various_journal.save
    assert various_journal.entries.reload.all?(&:closed?)
  end
  test 'accountant cannot be set on non-various journals' do
    bank_journal = journals(:journals_003)
    bank_journal.accountant = entities(:entities_016)
    refute bank_journal.valid?
  end
  test 'accountant cannot be on journals with cashes' do
    journal_with_cash = journals(:journals_002)
    journal_with_cash.nature = :various
    journal_with_cash.accountant = entities(:entities_016)
    refute journal_with_cash.valid?
  end
  test 'cannot set an accountant which has opened exchanges in its financial year' do
    financial_year = financial_years(:financial_years_025)
    journal = journals(:journals_001)
    journal.accountant = financial_year.accountant
    refute journal.valid?
  end
  test 'cannot remove accountant which has opened exchanges in its financial year' do
    journal = journals(:journals_010)
    journal.accountant = nil
    refute journal.valid?
  end
  test 'cannot be closed with an accountant' do
    journal = journals(:journals_001)
    assert journal.closable?
    journal.accountant = entities(:entities_016)
    refute journal.closable?
  end
  test 'cannot be reopened with an accountant' do
    journal = journals(:journals_001)
    assert journal.close!(Time.zone.now.to_date)
    assert journal.reopenable?
    journal.accountant = entities(:entities_016)
    refute journal.reopenable?
  end
end
