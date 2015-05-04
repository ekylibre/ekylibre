require 'test_helper'

class ExtractAggregatorsTest < CapybaraIntegrationTest

  setup do
    I18n.locale = @locale = ENV["LOCALE"] || I18n.default_locale
    visit("/authentication/sign_in?locale=#{@locale}")
    login_as(users(:users_001), scope: :user)
    visit('/backend')
  end

  teardown do
    Warden.test_reset!
  end

  test "export aggregators as different format" do
    visit('/backend/exports')
    links = page.all(:css, 'a.aggregator').map { |tag| tag[:href] }
    links.each do |link|
      visit(link)
    end
  end

end
