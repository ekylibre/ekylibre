require 'test_helper'

class CreateAnEstimateTest < CapybaraIntegrationTest
  setup do
    login_with_user
  end

  teardown do
    Warden.test_reset!
  end

  test 'create a sale from sales' do
    visit('/backend')
    first('#top').click_on(:trade.tl)
    click_link('actions.backend/sales.index'.t, href: backend_sales_path)
    within('.main-toolbar') do
      first('.btn-new').click
    end
    fill_unroll('sale_client_id', with: 'karam') # , select: "Gandhi Mohandas Karamchand, 196")
    check Sale.human_attribute_name(:letter_format)
    click_on :add_item.tl
    within('#items-table tbody.nested-fields:nth-of-type(1)') do
      fill_unroll('sale_item_variant_id', with: 'big bag')
      find(:css, '*[data-trade-component="unit_pretax_amount"]').set(100)
      find(:css, '*[data-trade-component="tax"]').find(:xpath, 'option[1]').select_option
      find(:css, '*[data-trade-component="quantity"]').set(15)
    end
    click_on :add_item.tl
    within('#items-table tbody.nested-fields:nth-of-type(2)') do
      fill_unroll('sale_item_variant_id', with: 'big bag')
      find(:css, '*[data-trade-component="unit_pretax_amount"]').set(100)
      find(:css, '*[data-trade-component="tax"]').find(:xpath, 'option[1]').select_option
      find(:css, '*[data-trade-component="quantity"]').set(15)
      find(:css, '*[data-trade-component="reduction_percentage"]').set(10)
    end
    click_on :add_item.tl
    within('#items-table tbody.nested-fields:nth-of-type(3)') do
      fill_unroll('sale_item_variant_id', with: 'big bag')
      find(:css, '*[data-trade-component="amount"]').set(500)
      find(:css, '*[data-trade-component="quantity"]').set(15)
    end
    sleep(1)
    click_on :add_item.tl
    within('#items-table tbody.nested-fields:nth-of-type(4)') do
      fill_unroll('sale_item_variant_id', with: 'big bag')
      find(:css, '*[data-trade-component="quantity"]').set(15)
      find(:css, '*[data-trade-component="pretax_amount"]').set(500)
    end
    click_on :create.tl
  end

  test 'create a sale from client' do
    visit('/backend')
    first('#top').click_on(:relationship.tl)
    click_link('actions.backend/entities.index'.t, href: backend_entities_path)
    within('#core .kujaku') do
      fill_in('q', with: 'yue')
      click_on :search.tl
    end
    click_on 'Yuey LTD'
    sleep(1)
    # click_link :timeline.tl
    page.execute_script("$(\"*[data-toggle='face'][href='timeline']\").trigger('click');")
    sleep(1)
    # within(:css, '.timeline-tool.tl-sales') do
    #   click_on 'actions.backend/sales.new'.t
    # end
    # seems timeline face isn't active
    find('.tl-sales', visible: :all).click_link('actions.backend/sales.new'.t, visible: :all)
    click_on :add_item.tl
    within('#items-table tbody.nested-fields:nth-of-type(1)') do
      fill_unroll('sale_item_variant_id', with: 'big bag')
      find(:css, '*[data-trade-component="unit_pretax_amount"]').set(100)
      find(:css, '*[data-trade-component="tax"]').find(:xpath, 'option[1]').select_option
      find(:css, '*[data-trade-component="quantity"]').set(15)
    end
    click_on :add_item.tl
    within('#items-table tbody.nested-fields:nth-of-type(2)') do
      fill_unroll('sale_item_variant_id', with: 'aceta')
      find(:css, '*[data-trade-component="unit_pretax_amount"]').set(100)
      find(:css, '*[data-trade-component="tax"]').find(:xpath, 'option[1]').select_option
      find(:css, '*[data-trade-component="quantity"]').set(15)
      find(:css, '*[data-trade-component="reduction_percentage"]').set(15)
    end
    click_on :add_item.tl
    within('#items-table tbody.nested-fields:nth-of-type(3)') do
      fill_unroll('sale_item_variant_id', with: 'mal')
      find(:css, '*[data-trade-component="amount"]').set(500)
      find(:css, '*[data-trade-component="quantity"]').set(15)
    end
    sleep(1)
    click_on :add_item.tl
    within('#items-table tbody.nested-fields:nth-of-type(4)') do
      fill_unroll('sale_item_variant_id', with: 'pot')
      find(:css, '*[data-trade-component="quantity"]').set(15)
      find(:css, '*[data-trade-component="pretax_amount"]').set(500)
    end
    click_on :create.tl
  end

  test 'create an empty sale from client' do
    visit('/backend')
    first('#top').click_on(:relationship.tl)
    click_link('actions.backend/entities.index'.t, href: backend_entities_path)
    within('#core .kujaku') do
      fill_in('q', with: 'yue')
      click_on :search.tl
    end
    click_on 'Yuey LTD'
    sleep(1)
    # click_link :timeline.tl
    page.execute_script("$(\"*[data-toggle='face'][href='timeline']\").click();")
    sleep(1)
    within(:xpath, '//*[contains(@class, "tl-sales")]') do
      click_on 'actions.backend/sales.new'.t
    end
    click_on :create.tl
  end
end
