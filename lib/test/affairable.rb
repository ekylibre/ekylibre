module Test
  module Affairable
    extend ActiveSupport::Concern

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
  end
end
