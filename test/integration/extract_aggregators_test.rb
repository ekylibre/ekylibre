require 'test_helper'

class ExtractAggregatorsTest < CapybaraIntegrationTest
  setup do
    login_with_user
  end

  teardown do
    Warden.test_reset!
  end

  test 'export aggregators as different format' do
    visit('/backend/exports')
    links = page.all(:css, 'a.aggregator').map { |tag| tag[:href] }
    links.each do |link|
      visit(link)
    end
  end
end
