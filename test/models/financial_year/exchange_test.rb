require 'test_helper'

module FinancialYearTest
  class ExchangeTest < Ekylibre::Testing::ApplicationTestCase::WithFixtures
    test 'cannot create exchange without accountant' do
      year = financial_years(:financial_years_025)
      refute year.can_create_exchange?
    end

    test 'cannot create exchange without journal booked by the accountant' do
      accountant = create(:entity, :accountant)
      year = financial_years(:financial_years_025)
      assert year.update_column(:accountant_id, accountant.id)
      refute year.can_create_exchange?
    end

    test 'create exchange when it has no opened exchange but journal booked by the accountant' do
      accountant = create(:entity, :accountant, :with_booked_journals)
      year = financial_years(:financial_years_025)
      assert year.update_column(:accountant_id, accountant.id)
      create(:financial_year_exchange, financial_year: year)
      assert year.can_create_exchange?
    end

    test 'cannot create exchange with opened exchanges' do
      accountant = create(:entity, :accountant, :with_booked_journals)
      year = financial_years(:financial_years_025)
      assert year.update_column(:accountant_id, accountant.id)
      create(:financial_year_exchange, :opened, financial_year: year)
      refute year.can_create_exchange?
    end

    test 'cannot change accountant with opened exchange' do
      accountant = create(:entity, :accountant, :with_booked_journals)
      year = financial_years(:financial_years_025)
      assert year.update_column(:accountant_id, accountant.id)
      create(:financial_year_exchange, :opened, financial_year: year)
      year.accountant = create(:entity, :accountant)
      refute year.valid?
    end

    test 'cannot change started_on with exchange' do
      accountant = create(:entity, :accountant, :with_booked_journals)
      year = financial_years(:financial_years_025)
      assert year.update_column(:accountant_id, accountant.id)
      create(:financial_year_exchange, :opened, financial_year: year)
      year.started_on = year.started_on + 1.day
      refute year.valid?
    end

    test 'has opened exchange with opened exchanges' do
      year = financial_years(:financial_years_025)
      accountant = create(:entity, :accountant, :with_booked_journals)
      assert year.update_column(:accountant_id, accountant.id)
      create(:financial_year_exchange, :opened, financial_year: year)
      assert year.opened_exchange?
    end

    test 'does not have opened exchange without exchange' do
      year = financial_years(:financial_years_025)
      accountant = create(:entity, :accountant, :with_booked_journals)
      assert year.update_column(:accountant_id, accountant.id)
      refute year.opened_exchange?
    end
  end
end
