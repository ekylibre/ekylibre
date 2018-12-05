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

class FinancialYearWriteableValidatorTest < ActiveSupport::TestCase

  class ValidatableWithFinancialYear
    include ActiveModel::Validations

    def printed_on
      Date.new(1993,04,30)
    end

    validates :printed_on, financial_year_writeable: true

    attr_accessor :financial_year, :creator_id
  end

  def setup
    @financial_year = Minitest::Mock.new

    def @financial_year.closed?
      false
    end

    def @financial_year.closing?
      false
    end

    def @financial_year.closure_in_preparation?
      false
    end

    def @financial_year.closer
      m = Minitest::Mock.new

      def m.id
        42
      end

      m
    end

    @record = ValidatableWithFinancialYear.new
    @record.financial_year = @financial_year
  end

  test 'fails_when_financial_year_is_closed' do
    def @financial_year.closed?
      true
    end

    refute_empty @record.tap(&:valid?).errors
  end

  test 'fails_when_financial_year_is_closing' do
    def @financial_year.closing?
      true
    end

    refute_empty @record.tap(&:valid?).errors
  end

  test 'fails_when_financial_year_is_closure_preparation_and_not_closer' do
    def @financial_year.closure_in_preparation?
      true
    end

    @record.creator_id = 10

    refute_empty @record.tap(&:valid?).errors
  end

  test 'succeed_when_financial_year_is_closure_preparation_and_closer' do
    def @financial_year.closure_in_preparation?
      true
    end

    @record.creator_id = 42

    assert_empty @record.tap(&:valid?).errors
  end

  test 'query_database_if_record_does_not_responds_to_financial_year' do
    validator = @validator = FinancialYearWriteableValidator.new({:attributes => {:printed_on => true}})

    assert_equal 'EX1992-93', validator.financial_year(Class.new, Date.new(1993, 04, 30)).code
  end

end