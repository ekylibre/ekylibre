# = Informations
#
# == License
#
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2009 Brice Texier, Thibaud Merigon
# Copyright (C) 2010-2012 Brice Texier
# Copyright (C) 2012-2016 Brice Texier, David Joulin
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
#  accounted_at                     :datetime
#  address_id                       :integer
#  affair_id                        :integer
#  amount                           :decimal(19, 4)   default(0.0), not null
#  annotation                       :text
#  client_id                        :integer          not null
#  codes                            :jsonb
#  conclusion                       :text
#  confirmed_at                     :datetime
#  created_at                       :datetime         not null
#  creator_id                       :integer
#  credit                           :boolean          default(FALSE), not null
#  credited_sale_id                 :integer
#  currency                         :string           not null
#  custom_fields                    :jsonb
#  delivery_address_id              :integer
#  description                      :text
#  downpayment_amount               :decimal(19, 4)   default(0.0), not null
#  expiration_delay                 :string
#  expired_at                       :datetime
#  function_title                   :string
#  has_downpayment                  :boolean          default(FALSE), not null
#  id                               :integer          not null, primary key
#  initial_number                   :string
#  introduction                     :text
#  invoice_address_id               :integer
#  invoiced_at                      :datetime
#  journal_entry_id                 :integer
#  letter_format                    :boolean          default(TRUE), not null
#  lock_version                     :integer          default(0), not null
#  nature_id                        :integer
#  number                           :string           not null
#  payment_at                       :datetime
#  payment_delay                    :string           not null
#  pretax_amount                    :decimal(19, 4)   default(0.0), not null
#  quantity_gap_on_invoice_entry_id :integer
#  reference_number                 :string
#  responsible_id                   :integer
#  state                            :string           not null
#  subject                          :string
#  transporter_id                   :integer
#  undelivered_invoice_entry_id     :integer
#  updated_at                       :datetime         not null
#  updater_id                       :integer
#

require 'test_helper'

class SaleTest < ActiveSupport::TestCase
  test_model_actions
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
end
