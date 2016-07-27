require 'test_helper'

class CreateAPurchaseTest < CapybaraIntegrationTest
  setup do
    login_with_user
  end

  teardown do
    Warden.test_reset!
  end

  test 'create a purchase from purchases' do
    visit('/backend')
    first('#top').click_on(:trade.tl)
    click_link('actions.backend/purchases.index'.t, href: backend_purchases_path)
    within('.main-toolbar') do
      first('.btn-new').click
    end
    fill_unroll('purchase_supplier_id', with: 'coop') # , select: "Gandhi Mohandas Karamchand, 196")
    click_on :add_item.tl
    within('#items-table tbody.nested-fields:nth-of-type(1)') do
      fill_unroll('purchase_item_variant_id', with: 'big bag')
      find(:css, '*[data-trade-component="unit_pretax_amount"]').set(100)
      find(:css, '*[data-trade-component="tax"]').find(:xpath, 'option[1]').select_option
      find(:css, '*[data-trade-component="quantity"]').set(15)
    end
    click_on :add_item.tl
    within('#items-table tbody.nested-fields:nth-of-type(2)') do
      fill_unroll('purchase_item_variant_id', with: 'big bag')
      find(:css, '*[data-trade-component="unit_pretax_amount"]').set(120)
      find(:css, '*[data-trade-component="tax"]').find(:xpath, 'option[1]').select_option
      find(:css, '*[data-trade-component="quantity"]').set(15)
      find(:css, '*[data-trade-component="reduction_percentage"]').set(15)
    end
    click_on :add_item.tl
    within('#items-table tbody.nested-fields:nth-of-type(3)') do
      fill_unroll('purchase_item_variant_id', with: 'big bag')
      find(:css, '*[data-trade-component="amount"]').set(500)
      find(:css, '*[data-trade-component="quantity"]').set(15)
    end
    sleep(1)
    click_on :add_item.tl
    within('#items-table tbody.nested-fields:nth-of-type(4)') do
      fill_unroll('purchase_item_variant_id', with: 'big bag')
      find(:css, '*[data-trade-component="quantity"]').set(15)
      find(:css, '*[data-trade-component="pretax_amount"]').set(500)
    end
    click_on :create.tl
  end

  test 'create a purchase from supplier' do
    visit('/backend')
    first('#top').click_on(:relationship.tl)
    click_link('actions.backend/entities.index'.t, href: backend_entities_path)
    within('#core .kujaku') do
      fill_in('q', with: 'taur')
      click_on :search.tl
    end
    click_on 'Taurus Plus'
    sleep(1)
    # click_link :timeline.tl
    page.execute_script("$(\"*[data-toggle='face'][href='timeline']\").click();")
    sleep(1)
	# p find('.timeline-tool.tl-purchases')
    within('.timeline-tool.tl-purchases') do
      click_on 'actions.backend/purchases.new'.t
    end
    click_on :add_item.tl
    within('#items-table tbody.nested-fields:nth-of-type(1)') do
      fill_unroll('purchase_item_variant_id', with: 'big bag')
      find(:css, '*[data-trade-component="unit_pretax_amount"]').set(100)
      find(:css, '*[data-trade-component="tax"]').find(:xpath, 'option[1]').select_option
      find(:css, '*[data-trade-component="quantity"]').set(15)
    end
    click_on :add_item.tl
    within('#items-table tbody.nested-fields:nth-of-type(2)') do
      fill_unroll('purchase_item_variant_id', with: 'aceta')
      find(:css, '*[data-trade-component="unit_pretax_amount"]').set(1.15)
      find(:css, '*[data-trade-component="tax"]').find(:xpath, 'option[1]').select_option
      find(:css, '*[data-trade-component="quantity"]').set(15)
      find(:css, '*[data-trade-component="reduction_percentage"]').set(15)
    end
    click_on :add_item.tl
    within('#items-table tbody.nested-fields:nth-of-type(3)') do
      fill_unroll('purchase_item_variant_id', with: 'mal')
      find(:css, '*[data-trade-component="amount"]').set(500)
      find(:css, '*[data-trade-component="quantity"]').set(15)
    end
    sleep(1)
    click_on :add_item.tl
    within('#items-table tbody.nested-fields:nth-of-type(4)') do
      fill_unroll('purchase_item_variant_id', with: 'pot')
      find(:css, '*[data-trade-component="quantity"]').set(15)
      find(:css, '*[data-trade-component="pretax_amount"]').set(500)
    end
    click_on :create.tl
  end

  test 'create an empty purchase from supplier' do
    visit('/backend')
    first('#top').click_on(:relationship.tl)
    click_link('actions.backend/entities.index'.t, href: backend_entities_path)
    within('#core .kujaku') do
      fill_in('q', with: 'taur')
      click_on :search.tl
    end
    click_on 'Taurus Plus'
    sleep(1)
    # click_link :timeline.tl
    page.execute_script("$(\"*[data-toggle='face'][href='timeline']\").click();")
    sleep(1)
    within('.timeline-tool.tl-purchases') do
      click_on 'actions.backend/purchases.new'.t
    end
    click_on :create.tl
  end
end
