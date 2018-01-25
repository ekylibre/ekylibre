# = Informations
#
# == License
#
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2009 Brice Texier, Thibaud Merigon
# Copyright (C) 2010-2012 Brice Texier
# Copyright (C) 2012-2018 Brice Texier, David Joulin
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
# == Table: affairs
#
#  accounted_at           :datetime
#  cash_session_id        :integer
#  closed                 :boolean          default(FALSE), not null
#  closed_at              :datetime
#  created_at             :datetime         not null
#  creator_id             :integer
#  credit                 :decimal(19, 4)   default(0.0), not null
#  currency               :string           not null
#  dead_line_at           :datetime
#  deals_count            :integer          default(0), not null
#  debit                  :decimal(19, 4)   default(0.0), not null
#  description            :text
#  id                     :integer          not null, primary key
#  journal_entry_id       :integer
#  letter                 :string
#  lock_version           :integer          default(0), not null
#  name                   :string
#  number                 :string
#  origin                 :string
#  pretax_amount          :decimal(19, 4)   default(0.0)
#  probability_percentage :decimal(19, 4)   default(0.0)
#  responsible_id         :integer
#  state                  :string
#  third_id               :integer          not null
#  type                   :string
#  updated_at             :datetime         not null
#  updater_id             :integer
#
require 'test_helper'

class AffairTest < ActiveSupport::TestCase
  test_model_actions

  # check that every model that can be affairable
  test 'affairables classes' do
    Affair.affairable_types.each do |type|
      model = type.constantize
      assert model.respond_to?(:deal_third), "Model #{type} cannot be used with affairs"
    end
  end

  test 'attachment' do
    sale = Sale.first
    assert sale
    affair = sale.affair
    assert affair
    affair.refresh! # Needed until affair#deals_count is up-to-date
    count = 1
    payment = IncomingPayment.where(payer: sale.client).first
    assert payment
    payment.affair.refresh!
    count += 1
    ret = affair.attach(payment)
    payment.reload
    assert_equal payment.affair, ret.affair
    assert_equal sale.affair, payment.affair
    assert_equal count, ret.affair.deals_count
  end

  test 'absorption' do
    sale = create(:sale)
    assert sale
    affair = sale.affair
    assert affair
    affair.refresh! # Needed until affair#deals_count is up-to-date
    count = affair.deals_count
    purchase = create(:purchase_invoice)
    assert purchase
    purchase.affair.refresh!
    count += purchase.affair.deals_count
    ret = affair.absorb!(purchase.affair)
    purchase.reload
    assert_equal affair, ret
    assert_equal sale.affair, purchase.affair
    assert_equal count, ret.deals_count
  end

  test 'letters journal entry items in the third account on save' do
    client = create(:entity, :client)
    account = client.client_account
    subject = create(:sale_affair, client: client)

    deal = create(:sale, nature: sale_natures(:sale_natures_001), affair: subject, state: 'draft')
    create :sale_item, sale: deal, tax: a_tax
    assert deal.invoice # bookkeep affair which creates its journal entry

    deal_entry_items_in_third_account = deal.journal_entry.items.select { |item| item.account == account }
    assert deal_entry_items_in_third_account.any?
    deal_entry_items_out_third_account = deal.journal_entry.items.reject { |item| item.account == account }
    assert deal_entry_items_out_third_account.any?

    subject.reload
    assert subject.save
    assert subject.letter

    assert deal_entry_items_in_third_account.all? { |item| item.letter.match '^' + subject.letter + '\*?$' }
    assert deal_entry_items_out_third_account.none?(&:letter)
  end

  test 'reuse letter on save while already lettered' do
    client = create(:entity, :client)
    subject = create(:sale_affair, client: client)

    deal = create(:sale, nature: sale_natures(:sale_natures_001), affair: subject, state: 'draft')
    create :sale_item, sale: deal, tax: a_tax
    assert deal.invoice # bookkeep affair which creates its journal entry

    subject.reload
    assert subject.save

    letter_on_first_save = subject.letter
    lettered_items_on_first_save = JournalEntryItem.where(letter: [letter_on_first_save, letter_on_first_save + '*']).pluck(:id).to_set
    assert letter_on_first_save.present?
    assert_not_empty lettered_items_on_first_save

    assert subject.save

    assert_equal letter_on_first_save, subject.letter
    assert_equal lettered_items_on_first_save, JournalEntryItem.where(letter: [letter_on_first_save, letter_on_first_save + '*']).pluck(:id).to_set
  end

  # Check that affair of given sale is actually closed perfectly
  def check_closed_state(affair)
    assert affair.balanced?,
           "Affair should be balanced:\n" + deal_entries(affair)
    assert affair.letterable_journal_entry_items.any?,
           "Affair should have letterable journal entry items:\n" + deal_entries(affair)
    assert affair.journal_entry_items_balanced?,
           "Journal entry items should be balanced:\n" + deal_entries(affair)
    assert !affair.multi_thirds?
    assert !affair.journal_entry_items_already_lettered?
    assert affair.match_with_accountancy?,
           "Affair should match with accountancy:\n" + deal_entries(affair)

    assert affair.letterable?

    letter = affair.letter
    assert letter.present?, 'After lettering, letter should be saved in affair'

    affair.letterable_journal_entry_items.each do |item|
      assert_equal letter, item.letter, "Journal entry item (account: #{item.account_number}, debit: #{item.debit}, debit: #{item.credit}) should be lettered with: #{letter}. Got: #{item.letter.inspect}"
    end

    debit = affair.letterable_journal_entry_items.sum(:debit)
    credit = affair.letterable_journal_entry_items.sum(:debit)
    assert_equal debit, credit
  end

  def deal_entries(affair)
    content = "debit: #{affair.debit.to_s.rjust(10).yellow}, credit: #{affair.credit.to_s.rjust(10).yellow}\n"
    content << "deals:\n"
    content << affair.deals.map { |d| e = d.journal_entry; " - #{d.number.ljust(20)} : #{e.debit.to_s.rjust(8)} | #{e.credit.to_s.rjust(8)} | #{d.deal_debit_amount.to_s.rjust(8)} | #{d.deal_credit_amount.to_s.rjust(8)} | #{d.direction if d.is_a?(Gap)}\n".red + e.items.map { |i| "   #{i.account_number.ljust(20).cyan} : #{i.debit.to_s.rjust(8)} | #{i.credit.to_s.rjust(8)} | #{i.letter}" }.join("\n") }.join("\n")
    content
  end

  def a_tax
    taxes(:taxes_001)
  end
end
