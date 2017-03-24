require 'test_helper'

class CreateAFixedAssetTest < CapybaraIntegrationTest
  setup do
    login_with_user
  end

  teardown do
    Warden.test_reset!
  end

  test 'create a fixed asset directly' do
    visit('/backend')
    first('#top').click_on(:accountancy.tl)
    click_link('actions.backend/fixed_assets.index'.t, href: backend_fixed_assets_path)
    within('.main-toolbar') do
      first('.btn-new').click
    end
    fill_in('Nom', with: 'Tracteur FENDT 850')
    fill_in('Montant amortissable', with: '240000')
    fill_in('Date de mise en service', with: '2016-01-01')

    fill_unroll('fixed_asset_journal_id', with: 'VOP') # , select: "Various operations, VOP")
    fill_unroll('fixed_asset_asset_account_id', with: '2154') # , select: "2154 - Matériels")
    fill_unroll('fixed_asset_allocation_account_id', with: '2815') # , select: "2815 - Ammortissements des installations techniques, matériels et outillage")
    fill_unroll('fixed_asset_expenses_account_id', with: '68115') # , select: "68115 - Dotat. aux amort. des équipements")

    click_on :create.tl
  end
end
