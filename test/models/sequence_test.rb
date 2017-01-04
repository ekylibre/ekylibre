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
# == Table: sequences
#
#  created_at       :datetime         not null
#  creator_id       :integer
#  id               :integer          not null, primary key
#  last_cweek       :integer
#  last_month       :integer
#  last_number      :integer
#  last_year        :integer
#  lock_version     :integer          default(0), not null
#  name             :string           not null
#  number_format    :string           not null
#  number_increment :integer          default(1), not null
#  number_start     :integer          default(1), not null
#  period           :string           default("number"), not null
#  updated_at       :datetime         not null
#  updater_id       :integer
#  usage            :string
#

require 'test_helper'

class SequenceTest < ActiveSupport::TestCase
  test_model_actions

  test 'next values' do
    sequence = Sequence.find_by(usage: :sales_invoices)
    sequence.update_attributes!(number_format: 'Y[year]M[month]N[number|8]', period: :month)

    val1 = sequence.next_value
    val2 = sequence.next_value!
    assert_equal val1, val2
  end

  test 'reset' do
    sequence = Sequence.find_by(usage: :sales_invoices)
    sequence.update_attributes!(number_format: 'Y[year]M[month]N[number|8]', period: :month)

    sequence.next_value!
    val1 = sequence.last_number
    sequence.next_value!
    assert_equal val1 + 1, sequence.last_number
    sequence.next_value!
    sequence.next_value!
    sequence.next_value!
    sequence.next_value!
    future = Date.today >> 1
    value = sequence.next_value(future)
    assert_equal "Y#{future.year}M#{future.month}N00000001", value
  end
end
