require 'test_helper'

class SaleInvoicingTest < Ekylibre::Testing::ApplicationTestCase::WithFixtures
  setup do
    @sale = Sale.new(client: entities(:entities_003), nature: sale_natures(:sale_natures_001), invoiced_at: DateTime.parse('2019-02-02T00:00:00Z'))
    assert @sale.save, @sale.errors.inspect
    assert_equal Time.zone.now.to_date, @sale.created_at.to_date
    assert !@sale.affair.nil?, 'A sale must be linked to an affair'
    assert_equal @sale.amount, @sale.affair_credit, "Affair amount is not the same as the sale amount (#{@sale.affair.inspect})"

    (1..10).each do |_|
      item = create :sale_item, sale: @sale
      assert item.save, item.errors.inspect
    end
    @sale.reload
    assert_equal 'draft', @sale.state
  end

  test "A sale should be invoicable" do
    assert @sale.propose
    assert_equal 'estimate', @sale.state
    assert @sale.can_invoice?
    assert @sale.confirm(Date.new(2019, 2, 1))
    assert @sale.invoice
    assert_equal 'invoice', @sale.state
  end

  test "A sale should be invoicable with a description containing windows newlines" do
    assert @sale.update description: "A description with \r\nwindows newline"
    assert @sale.invoice
  end

  test "A sale should be invoicable with a description containing unix newlines" do
    assert @sale.update description: "A description with \nunix newline"
    assert @sale.invoice
  end
end
