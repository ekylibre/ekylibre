require 'test_helper'

class FinancialYearExchangeExportMailerTest < ActionMailer::TestCase
  include FactoryBot::Syntax::Methods

  setup do
    FinancialYear.delete_all
    FinancialYearExchange.delete_all
    accountant = create(:entity, :with_email)
    fy = create(:financial_year, year: 2021, accountant: accountant)
    @exchange = create(:financial_year_exchange, financial_year: fy)
    @user = create(:user)
    @file = File.new(Dir.pwd + "/tmp/test.pdf", "w")
    File.open(@file, "w") { |f| f.write("Random stuff") }
  end

  test 'notify accountant' do
    email = FinancialYearExchangeExportMailer.notify_accountant(@exchange, @user, @file, 'my_file.pdf')
    assert_emails 1 do
      email.deliver_now
    end

    assert_equal email.from, [@user.email]
    assert_equal email.to, [@exchange.accountant_email]
    assert_equal email.attachments.count, 1
  end
end
