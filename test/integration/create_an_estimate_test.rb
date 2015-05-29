require 'test_helper'

class CancelASalesInvoiceTest < CapybaraIntegrationTest

  setup do
    I18n.locale = @locale = ENV["LOCALE"] || I18n.default_locale
    visit("/authentication/sign_in?locale=#{@locale}")
    login_as(users(:users_001), scope: :user)
  end

  teardown do
    Warden.test_reset!
  end

  test "create a sale" do
    visit('/backend')
    first('#top').click_on(:trade.tl)
    click_link("actions.backend/sales.index".t, href: backend_sales_path)
    within('.main-toolbar') do
      first('.btn-new').click
    end
    fill_unroll('sale_client_id', with: "am", select: "Camargue milk, 00000010")
    click_on :add_item.tl
    click_on :add_item.tl
    click_on :add_item.tl
    click_on :add_item.tl
    click_on :create.tl
  end

end
