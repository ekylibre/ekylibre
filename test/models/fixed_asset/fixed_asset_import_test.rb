require 'test_helper'

module FixedAssetTest
  class FixedAssetImportTest < Ekylibre::Testing::ApplicationTestCase::WithFixtures
    setup do
      @variant = ProductNatureVariant.import_from_nomenclature(:tractor)
      @entity = Entity.create!(last_name: 'JOHN DEERE SA')
      @address = @entity.addresses.create!(canal: 'mail', mail_line_1: 'Yolo', mail_line_2: 'Another test')

      @building_division_variant = ProductNatureVariant.import_from_nomenclature(:building_division)
      @storage = BuildingDivision.create!(
        variant: @building_division_variant,
        name: 'Tractor Stockage',
        initial_shape: Charta.new_geometry('SRID=4326;MULTIPOLYGON(((-0.813218951225281 45.5985699786537,-0.813113003969193 45.5985455816635,-0.81300538033247 45.5987766488858,-0.813106298446655 45.5987876744046,-0.813218951225281 45.5985699786537)))')
      )

      @product = @variant.products.create!(
        initial_container: @storage,
        initial_population: 1,
        name: 'JD 5201'
      )

      currency = 'EUR'

      @journal = Journal.where(nature: 'various', currency: currency).first

      @waiting_account = Account.find_or_import_from_nomenclature :suspense
      @asset_account = Account.find_or_create_by_number('998765')
      @allocation_account = Account.find_or_create_by_number('998764')
      @expenses_account = Account.find_or_create_by_number('998763')

      @started_on = Date.parse('2017-01-01')

      @up_to = Date.parse('2017-04-20')

      @sold_on = Date.parse('2017-04-20')
    end

    test 'A FixedAsset created before the first opened FinancialYear creates the correct depreciations entries' do
      FinancialYear.delete_all
      (2010..2015).each do |year|
        fy = FinancialYear.new(started_on: Date.new(year, 1, 1), stopped_on: Date.new(year, 12, 31), state: :locked)
        assert fy.save
      end
      [2016, 2017].each do |year|
        fy = FinancialYear.new(started_on: Date.new(year, 1, 1), stopped_on: Date.new(year, 12, 31))
        assert fy.save
      end

      fa = FixedAsset.new(
        name: @product.name,
        depreciable_amount: 50_000,
        depreciation_method: :linear,
        depreciation_percentage: 10,
        started_on: '2008-01-01',
        journal: @journal,
        asset_account: @asset_account,
        expenses_account: @expenses_account,
        allocation_account: @allocation_account
      )

      assert fa.save
      deps = fa.depreciations.to_a
      assert_equal 10, deps.length
      partitionned = deps.partition { |dep| dep.started_on.year < 2016 }

      assert_equal 8, partitionned[0].length
      assert partitionned[0].all? &:locked?

      assert_not partitionned[1].any? &:locked?
    end

    test 'enabling a FixedAssed on a date where no FinancialYear opened creates the correct journal entries' do
      FinancialYear.delete_all
      (2010..2015).each do |year|
        FinancialYear.create!(started_on: Date.new(year, 1, 1), stopped_on: Date.new(year, 12, 31), state: :locked)
      end
      [2016, 2017].each do |year|
        FinancialYear.create!(started_on: Date.new(year, 1, 1), stopped_on: Date.new(year, 12, 31))
      end

      fa = FixedAsset.new(
        name: @product.name,
        depreciable_amount: 50_000,
        depreciation_method: :linear,
        depreciation_percentage: 10,
        started_on: '2008-01-01',
        journal: @journal,
        asset_account: @asset_account,
        expenses_account: @expenses_account,
        allocation_account: @allocation_account
      )

      assert fa.save

      state, _ = fa.start_up
      assert state
      fa.reload

      fa_je = fa.journal_entry
      assert fa_je.balanced?

      jeis_debit, jeis_credit = fa_je.items.partition { |e| e.debit > 0 }
      assert_equal 50_000, jeis_debit[0].debit
      assert_equal 50_000, jeis_credit[0].credit

      current_fy = FinancialYear.opened.first

      locked, opened = fa.depreciations.partition { |fad| fad.started_on < current_fy.started_on }
      locked.each do |dep|
        assert dep.locked?, "All depreciations before the first FinancialYear should be locked"
        assert dep.has_journal_entry?, "All locked depreciations should be automatically accounted"

        je = dep.journal_entry
        assert_equal Date.new(2016, 1, 1), je.printed_on, "The journal entry should be printed on at the begining of the first opened FinancialYear"

        debit, credit = je.items.partition { |i| i.debit > 0 }
        debit = debit.first
        credit = credit.first

        assert_equal 5_000, debit.debit, "The amount of the journal entry should be 5000"
        assert_equal 5_000, credit.credit, "The amount of the journal entry should be 5000"

        assert_equal @waiting_account, debit.account, "The debit account should be the waiting account (471)"
        assert_equal @allocation_account, credit.account, "The credited account should be the allocation account of the linked FixedAsset"
      end

      assert_not opened.any?(&:locked?), "All depreciations after the first opened FinancialYear should not be locked"
      assert_not opened.any?(&:has_journal_entry?), "All depreciations after the first opened FinancialYear should not have a journal entry"
    end
  end
end