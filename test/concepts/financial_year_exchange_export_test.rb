require 'test_helper'

class FinancialYearExchangeExportTest < Ekylibre::Testing::ApplicationTestCase::WithFixtures
  test 'csv export empty exchange' do
    financial_year = FinancialYear.where(closed: false).order(started_on: :desc).first
    exchange = create(:financial_year_exchange, financial_year: financial_year)

    # TEST NORMAL HEADER
    FinancialYearExchanges::CsvExport.new.generate_file(exchange) do |file_path|
      file_path.open
      assert_equal [FinancialYearExchanges::CsvExport::HEADERS.join(",") + "\n"], file_path.readlines
      file_path.close
    end

    # TEST ISACOMPTA HEADER
    exchange.update(format: 'isacompta')
    FinancialYearExchanges::CsvExport.new.generate_file(exchange) do |file_path|
      file_path.open
      assert_equal [FinancialYearExchanges::CsvExport::ISACOMPTA_HEADERS.join(",") + "\n"], file_path.readlines
      file_path.close
    end
  end

end
