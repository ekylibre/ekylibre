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
# == Table: financial_years
#
#  closed                :boolean          not null
#  code                  :string(20)       not null
#  created_at            :datetime         not null
#  creator_id            :integer
#  currency              :string(3)        not null
#  currency_precision    :integer
#  id                    :integer          not null, primary key
#  last_journal_entry_id :integer
#  lock_version          :integer          default(0), not null
#  started_at            :datetime         not null
#  stopped_at            :datetime         not null
#  updated_at            :datetime         not null
#  updater_id            :integer
#


require 'test_helper'

class FinancialYearTest < ActiveSupport::TestCase

  def test_fixtures
    FinancialYear.find_each do |record|
      assert record.valid?, "Record ##{record.name} is invalid. #{record.errors.full_messages.to_sentence}"
    end
  end
    
  def test_chronology
    first_year = financial_years(:financial_years_001)
    assert_not_nil first_year

    assert_nil first_year.previous, "No previous financial year expected"

    assert_not_nil first_year.next, "No next financial year found... #{first_year.stopped_at}"

    assert_not_nil first_year.next.previous
    assert_equal first_year, first_year.next.previous

    assert_not_nil FinancialYear.at(Time.now + 50.years)
  end

end
