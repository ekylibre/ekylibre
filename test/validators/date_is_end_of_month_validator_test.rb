# = Informations
#
# == License
#
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2009 Brice Texier, Thibaud Merigon
# Copyright (C) 2010-2012 Brice Texier
# Copyright (C) 2012-2018 Brice Texier, David Joulin
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

require 'test_helper'

class DateIsEndOfMonthValidatorTest < Ekylibre::Testing::ApplicationTestCase::WithFixtures

  class ValidatableWithDateIsEndOfMonth
    include ActiveModel::Validations

    # def initialize
    #   @printed_on = Date.new(1993, 04, 30)
    # end

    validates :date, date_is_end_of_month: true

    attr_accessor :date
  end

  def setup
    @date = ValidatableWithDateIsEndOfMonth.new
  end

  test 'fails when the day is not the last of the month' do
    @date.date = "2018-05-08"

    refute_empty @date.tap(&:valid?).errors
  end

  test 'succeed when the day the last of the month' do
    @date.date = "2018-05-31"

    assert_empty @date.tap(&:valid?).errors
  end

end