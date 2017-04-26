# = Informations
#
# == License
#
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2009 Brice Texier, Thibaud Merigon
# Copyright (C) 2010-2012 Brice Texier
# Copyright (C) 2012-2017 Brice Texier, David Joulin
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see http://www.gnu.org/licenses.
#
# == Table: sales
#
#  accounted_at                             :datetime
#  address_id                               :integer
#  affair_id                                :integer
#  amount                                   :decimal(19, 4)   default(0.0), not null
#  annotation                               :text
#  client_id                                :integer          not null
#  codes                                    :jsonb
#  conclusion                               :text
#  confirmed_at                             :datetime
#  created_at                               :datetime         not null
#  creator_id                               :integer
#  credit                                   :boolean          default(FALSE), not null
#  credited_sale_id                         :integer
#  currency                                 :string           not null
#  custom_fields                            :jsonb
#  delivery_address_id                      :integer
#  description                              :text
#  downpayment_amount                       :decimal(19, 4)   default(0.0), not null
#  expiration_delay                         :string
#  expired_at                               :datetime
#  function_title                           :string
#  has_downpayment                          :boolean          default(FALSE), not null
#  id                                       :integer          not null, primary key
#  initial_number                           :string
#  introduction                             :text
#  invoice_address_id                       :integer
#  invoiced_at                              :datetime
#  journal_entry_id                         :integer
#  letter_format                            :boolean          default(TRUE), not null
#  lock_version                             :integer          default(0), not null
#  nature_id                                :integer
#  number                                   :string           not null
#  payment_at                               :datetime
#  payment_delay                            :string           not null
#  pretax_amount                            :decimal(19, 4)   default(0.0), not null
#  quantity_gap_on_invoice_journal_entry_id :integer
#  reference_number                         :string
#  responsible_id                           :integer
#  state                                    :string           not null
#  subject                                  :string
#  transporter_id                           :integer
#  undelivered_invoice_journal_entry_id     :integer
#  updated_at                               :datetime         not null
#  updater_id                               :integer
#

require 'test_helper'

class SaleTest < ActiveSupport::TestCase
  test_model_actions

  setup do
    @variant = ProductNatureVariant.import_from_nomenclature(:carrot)
  end

  test 'rounds' do
    nature = SaleNature.find_or_create_by(with_accounting: true)
    assert nature
    client = Entity.normal.first
    assert client
    sale = Sale.create!(nature: nature, client: client)
    assert sale
    variants = ProductNatureVariant.where(nature: ProductNature.where(population_counting: :decimal))
    # Standard case
    standard_vat = Tax.create!(
      name: 'Standard',
      amount: 20,
      nature: :normal_vat,
      collect_account: Account.find_or_create_by_number('45661'),
      deduction_account: Account.find_or_create_by_number('45671'),
      country: :fr
    )
    first_item = sale.items.create!(variant: variants.first, quantity: 4, unit_pretax_amount: 100, tax: standard_vat)
    assert first_item
    assert_equal 480, first_item.amount
    assert_equal 480, sale.amount
    # Limit case
    reduced_vat = Tax.create!(
      name: 'Reduced',
      amount: 5.5,
      nature: :normal_vat,
      collect_account: Account.find_or_create_by_number('45662'),
      deduction_account: Account.find_or_create_by_number('45672'),
      country: :fr
    )
    second_item = sale.items.create!(variant: variants.second, quantity: 4, unit_pretax_amount: 3.791, tax: reduced_vat)
    assert second_item
    assert_equal 16, second_item.amount
    assert_equal 496, sale.amount

    assert sale.propose!
    assert sale.confirm!
    assert sale.invoice!

    sale.reload
    entry = sale.journal_entry

    assert entry.present?, 'Journal entry must be present after invoicing'

    assert_equal 5, entry.items.count
    assert 80.0, entry.items.find_by(account_id: standard_vat.collect_account_id).credit
    assert 400.0, entry.items.find_by(account_id: first_item.account_id).credit
    assert 0.84, entry.items.find_by(account_id: reduced_vat.collect_account_id).credit
    assert 15.16, entry.items.find_by(account_id: second_item.account_id).credit
    assert 496, entry.items.find_by(account_id: client.account(:client).id).debit
  end

  test 'unit pretax amount calculation based on total pretax amount' do
    nature = SaleNature.first
    assert nature
    sale = Sale.create!(nature: nature, client: Entity.normal.first)
    assert sale
    variants = ProductNatureVariant.where(nature: ProductNature.where(population_counting: :decimal))
    tax = Tax.create!(
      name: 'Standard',
      amount: 20,
      nature: :normal_vat,
      collect_account: Account.find_or_create_by_number('4566'),
      deduction_account: Account.find_or_create_by_number('4567'),
      country: :fr
    )
    # Calculates unit_pretax_amount based on pretax_amount
    item = sale.items.create!(variant: variants.first, quantity: 2, pretax_amount: 225, tax: tax, compute_from: 'pretax_amount')
    assert item
    assert_equal 112.50, item.unit_pretax_amount
    assert_equal 270, item.amount
  end

  test 'duplicatablity' do
    count = 0
    Sale.find_each do |sale|
      if sale.duplicatable?
        sale.duplicate
        count += 1
      end
    end
    assert count > 0, 'No sale has been duplicated for test'
  end

  context 'A minimal configuration' do
    setup do
      DocumentTemplate.load_defaults(locale: :fra)
      DocumentTemplate.update_all({ archiving: 'last' }, nature: 'sales_invoice')
    end

    context 'A sale' do
      setup do
        @sale = sales(:sales_001)
        assert @sale.draft?
        assert @sale.save
      end

      # should "be invoiced" do
      #   assert !@sale.invoice

      #   item = @sale.items.new(:quantity => 12, :product_id => products(:animals_001).id) # :price_id => product_nature_prices(:product_nature_prices_001).id) # , :warehouse_id => products(:warehouses_001).id)
      #   assert item.save, item.errors.inspect
      #   item = @sale.items.new(:quantity => 25, :product_id => products(:matters_001).id) # :price_id => product_nature_prices(:product_nature_prices_003).id) # , :warehouse_id => products(:warehouses_001).id)
      #   assert item.save, item.errors.inspect
      #   @sale.reload
      #   assert_equal "draft", @sale.state
      #   assert @sale.propose
      #   assert_equal "estimate", @sale.state
      #   assert @sale.can_invoice?, "Deliverables: " + @sale.items.collect{|l| l.product.attributes.inspect}.to_sentence
      #   assert @sale.confirm
      #   assert @sale.invoice
      #   assert_equal "invoice", @sale.state
      # end

      # should "be printed" do
      #   DocumentTemplate.print(:sales_order, @sale)
      #   assert_nothing_raised do
      #   DocumentTemplate.print(:sales_order, @sale)

      # # DocumentTemplate.print(:sales_order, @sale.number, Ekylibre::Datasource::SalesOrder.to_xml(@sale))
      # # DocumentTemplate.print(:sales_order, @sale.number, @sale)

      # # DocumentTemplate.print(:balance, started_at, stopped_at, options...)

      # # balance_template.print(started_at, stopped_at, options...)

      # # DocumentTemplate.print(:animal_list)
      # # animal_list_template.print

      # # DocumentTemplate.print(:animals, :ill => true, :active => true, :external => true, :variety => 'bos')

      # # DocumentTemplate.print(:sales_order, @sale.number, @sale.to_xml(qsdqsdqsd))
      # # DocumentTemplate.print(:sales_order, @sale.number, @sale.to_xml(qsdqsdqsd))
      # # DocumentTemplate.print(@sale.to_xml, :sales_order, :sales_order => @sale)
      # end
    end

    context 'A sales invoice' do
      setup do
        @sale = Sale.new(client: entities(:entities_003), nature: sale_natures(:sale_natures_001))
        assert @sale.save, @sale.errors.inspect
        assert_equal Date.today, @sale.created_at.to_date
        assert !@sale.affair.nil?, 'A sale must be linked to an affair'
        assert_equal @sale.amount, @sale.affair_credit, "Affair amount is not the same as the sale amount (#{@sale.affair.inspect})"

        for y in 1..10
          item = @sale.items.new(quantity: 1 + rand(70) * rand, product_id: products("matters_#{(3 + rand(2)).to_s.rjust(3, '0')}".to_sym).id) # , :price_id => product_nature_prices("product_nature_prices_#{(3+rand(2)).to_s.rjust(3, '0')}".to_sym).id, :warehouse_id => products(:warehouses_001).id)
          # assert item.valid?, [product.prices, item.price].inspect
          assert item.save, item.errors.inspect
        end
        @sale.reload
        assert_equal 'draft', @sale.state
        assert @sale.propose
        assert_equal 'estimate', @sale.state
        assert @sale.can_invoice?, 'Deliverables: ' + @sale.items.collect { |l| l.product.attributes.inspect }.to_sentence
        assert @sale.confirm
        assert @sale.invoice
        assert_equal 'invoice', @sale.state
        assert_equal Date.today, @sale.invoiced_at.to_date
      end

      # # @TODO test have to be modify in order to work when updating model was finished
      # should "not be updateable" do
      #   amount = @sale.amount
      #   assert_raise ActiveModel::MassAssignmentSecurity::Error do
      #     @sale.update_attributes(:amount => amount.to_i + 50)
      #   end
      #   @sale.reload
      #   assert_equal amount, @sale.amount, "State of sale is: #{@sale.state}"
      # end

      # should "be printed and archived" do
      #   data = []
      #   DocumentTemplate.print(:sales_invoice, @sale)
      #   assert_nothing_raised do
      #     data << Digest::SHA256.hexdigest(DocumentTemplate.print(:sales_invoice, @sale)[0])
      #   end
      #   assert_nothing_raised do
      #     data << Digest::SHA256.hexdigest(DocumentTemplate.print(:sales_invoice, @sale)[0])
      #   end
      #   assert_nothing_raised do
      #     data << Digest::SHA256.hexdigest(DocumentTemplate.print(:sales_invoice, @sale)[0])
      #   end
      #   assert_equal data[0], data[1], "The template doesn't seem to be archived"
      #   assert_equal data[0], data[2], "The template doesn't seem to be archived or understand Integers"
      # end
    end
  end

  test 'default_currency is nature\'s currency if currency is not specified' do
    Catalog.delete_all
    SaleNature.delete_all
    Entity.delete_all
    Sale.delete_all

    catalog    = Catalog.create!(code: 'food', name: 'Noncontaminated produce')
    nature     = SaleNature.create!(currency: 'EUR', name: 'Perishables', catalog: catalog)
    max        = Entity.create!(first_name: 'Max', last_name: 'Rockatansky', nature: :contact)
    with       = Sale.create!(client: max, nature: nature, currency: 'USD')
    without    = Sale.create!(client: max, nature: nature)

    assert_equal 'USD', with.default_currency
    assert_equal 'EUR', without.default_currency
  end

  test 'affair_class points to correct class' do
    assert_equal SaleAffair, Sale.affair_class
  end

  test 'Test variant specified when bookkeep' do
    nature = SaleNature.first
    standard_vat = Tax.create!(
      name: 'Standard',
      amount: 20,
      nature: :normal_vat,
      collect_account: Account.find_or_create_by_number('45661'),
      deduction_account: Account.find_or_create_by_number('45671'),

      country: :fr
    )

    sale = Sale.create!(nature: nature, client: Entity.normal.first, state: :order)
    sale.items.create!(variant: @variant, quantity: 4, unit_pretax_amount: 100, tax: standard_vat)
    sale.reload

    assert sale.invoice

    journal_entry_items = sale.journal_entry.items
    account_ids = journal_entry_items.pluck(:account_id)

    sale_account = Account.where(id: account_ids).where("number LIKE '7%'").first
    jei_s = journal_entry_items.where(account_id: sale_account.id).first

    # jei_s variant must be defined
    assert_not jei_s.variant.nil?
    assert_equal jei_s.variant, @variant
  end
end
