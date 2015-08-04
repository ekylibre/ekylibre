require 'test_helper'

class CancelASalesInvoiceTest < CapybaraIntegrationTest
  setup do
    I18n.locale = @locale = ENV['LOCALE'] || I18n.default_locale
    visit("/authentication/sign_in?locale=#{@locale}")
    login_as(users(:users_001), scope: :user)
    visit('/backend')
  end

  teardown do
    Warden.test_reset!
  end

  test 'cancel a sales invoice' do
    visit('/backend/sales')
    shoot_screen 'sales/index'
    number = 'F2014000002'
    sale = Sale.find_by(number: number)
    click_link(number)
    click_link(:cancel.tl)
    click_on(:create.tl)
    shoot_screen 'sale_credits/create'
    count = sale.reload.credits.count
    assert_equal 1, count, "Only credit is expected. Got: #{count}"
    credit = sale.credits.first
    assert_equal 0, sale.amount + credit.amount, "Amounts of sale and its credit are not matching (#{sale.amount} and #{credit.amount})"
  end
end
