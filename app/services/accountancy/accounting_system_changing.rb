# frozen_string_literal: true

module Accountancy
  class AccountingSystemChanging
    attr_reader :result_infos
    def initialize(financial_year_id:, old_accounting_system:, new_accounting_system: )
      @financial_year = FinancialYear.find_by(id: financial_year_id)
      @old_accounting_system = old_accounting_system
      @new_accounting_system = new_accounting_system
      @started_on = @financial_year.started_on
      @stopped_on = @financial_year.stopped_on
      @started_at = @started_on.to_time.beginning_of_day
      @stopped_at = @stopped_on.to_time.end_of_day
      @others_fy_ids = FinancialYear.where.not(id: @financial_year.id).pluck(:id)
      @account_normalizer = Accountancy::AccountNumberNormalizer.build
      @account_padded_normalizer = Accountancy::AccountNumberNormalizer.build_deprecated_for_account_creation
      @result_infos = {}
      @count_accounts = 0
      @count_entries = 0
      @logger ||= Logger.new(File.join(Rails.root, 'log', "account-changing-#{Ekylibre::Tenant.current.to_s}-#{@financial_year.code.to_s}.log"))
    end

    def perform
      @logger.info("----------------------- Migrate from : #{@old_accounting_system} to #{@new_accounting_system} -----------------------")
      accounts = Account.all
      accounts_up_to_standard_length = accounts.where('LENGTH(number) > ?', @account_normalizer.standard_length)
      standard_accounts = accounts - accounts_up_to_standard_length
      if accounts_up_to_standard_length.count > 0
        @logger.info("----------------------- somes account number length are > #{@account_normalizer.standard_length.to_s} -----------------------")
        @logger.info("Accounts IDS #{accounts_up_to_standard_length.pluck(:id)} are up to standard length : #{@account_normalizer.standard_length}")
        @result_infos[:error] = "Accounts IDS #{accounts_up_to_standard_length.pluck(:id)} are up to standard length : #{@account_normalizer.standard_length}"
      end
      ApplicationRecord.transaction do
        @logger.info("----------------------- #{standard_accounts.count.to_s} standard accounts actives with usages to proceed -----------------------")
        standard_accounts.each do |account|
          @logger.info("-------- Account NUMBER : #{account.number} | ID: #{account.id} -----------")
          change_account_number(account)
        end
        # TODO: proceed non standard accounts
        @logger.info("-------- Update all entries on current financial year -----------")
        JournalEntry.where(financial_year_id: @financial_year.id).map(&:save)
        @logger.info("-------- Set accounting_system global preference to #{@new_accounting_system} -----------")
        Preference.set! :accounting_system, @new_accounting_system
      end
      @result_infos[:accounting_system] = @new_accounting_system
      @result_infos[:count_accounts] = @count_accounts
      @result_infos[:count_entries] = @count_entries
    end

    private

      # update account number based on usage
      def change_account_number(account)
        # because it could attempt to update a stale object if another account call to update the same object before
        account.reload
        # find usage in Onoma
        if account.usages.present?
          o = Onoma::Account.find(account.usages)
        else
          near_usage = Account.find_parent_usage(account.number)
          o = Onoma::Account.find(near_usage)
        end
        return nil if o.nil?

        old_radical_number = o.send(@old_accounting_system)
        new_radical_number = o.send(@new_accounting_system)
        real_number = account.number.to_s
        if old_radical_number == new_radical_number
          @logger.info("--- radical_number is the same #{old_radical_number} VS #{new_radical_number}---")
        elsif real_number.start_with? new_radical_number
          @logger.info("--- number start already with new radical #{real_number} / #{new_radical_number}---")
        elsif real_number.start_with? old_radical_number
          end_number = real_number[old_radical_number.length..-1]
          new_number = new_radical_number + end_number
          @logger.info("--- new number is #{new_number} ---")
          normalized_number = compute_normalize_number(new_number)
          @logger.info("--- normalized new number is #{normalized_number} ---")
          already_existing_new_account = Account.find_by(number: normalized_number)
          @logger.info("--- account already exist with new number | ID : #{already_existing_new_account.id} / NAME : #{already_existing_new_account.name} / NUMBER : #{already_existing_new_account.number} ---") if already_existing_new_account.present?
          jei_of_account_existing_on_other_fy = JournalEntryItem.where(account_id: account.id, financial_year_id: @others_fy_ids)
          if jei_of_account_existing_on_other_fy.any?
            @logger.info("--- #{jei_of_account_existing_on_other_fy.count.to_s} entries exist on existing account ---")
            if already_existing_new_account.present?
              new_acc = already_existing_new_account
              @logger.info("--- update already_existing_new_account ---")
              new_acc.update!(usages: account.usages, active: true, nature: account.nature)
            else
              # create a new account with same parameter
              @logger.info("--- create new account #{normalized_number} with same parameter... ---")
              new_acc = Account.create!(debtor: account.debtor,
                                        description: "Replace #{real_number} when changing accounting system to #{@new_accounting_system}",
                                        name: account.name,
                                        nature: account.nature,
                                        number: normalized_number,
                                        usages: account.usages,
                                        reconcilable: account.reconcilable,
                                        active: true)
              @logger.info("--- New account #{new_acc.id.to_s} / #{new_acc.number} created ---") if new_acc.present?
            end
            # update existing link of old account with new account on current fy
            update_existing_links(account, new_acc)
            @logger.info("--- make old account inactive ---")
            account.update!(active: false, description: "Replace by #{normalized_number} when changing accounting system to #{@new_accounting_system}")
          elsif already_existing_new_account.present?
            @logger.info("--- update already_existing_new_account ---")
            already_existing_new_account.update!(usages: account.usages, active: true, nature: account.nature)
            @logger.info("--- make old account inactive ---")
            account.update!(active: false, description: "Replace by #{normalized_number} when changing accounting system to #{@new_accounting_system}")
          else
            @logger.info("--- update account ---")
            account.update!(number: normalized_number, description: "Replace #{real_number} when changing accounting system to #{@new_accounting_system}")
          end
          @count_accounts += 1
        end
      end

      def update_existing_links(old_account, new_account)
        # existing jei on current fy
        existing_entries = old_account.journal_entry_items.where(financial_year_id: @financial_year.id)
        @count_entries += existing_entries.count
        @logger.info("--- #{existing_entries.count.to_s} existing entries on current fy on old account #{old_account.number}---")
        @logger.info("--- Updating existing entries with new_account #{new_account.number} ---")
        existing_entries.update_all(account_id: new_account.id) if existing_entries.any?
        # update category (other job launch on update for sale, purchase...)
        @logger.info("--- Updating categories accounts with new_account #{new_account.number} ---")
        old_account.charges_categories.update_all(charge_account_id: new_account.id) if old_account.charges_categories.any?
        old_account.products_categories.update_all(product_account_id: new_account.id) if old_account.products_categories.any?
        old_account.stocks_categories.update_all(stock_account_id: new_account.id) if old_account.stocks_categories.any?
        old_account.stocks_movement_categories.update_all(stock_movement_account_id: new_account.id) if old_account.stocks_movement_categories.any?
        # update loans
        @logger.info("--- Updating loans accounts with new_account #{new_account.number} ---")
        old_account.loans.update_all(loan_account_id: new_account.id) if old_account.loans.any?
        old_account.loans_as_interest.update_all(interest_account_id: new_account.id) if old_account.loans_as_interest.any?
        old_account.loans_as_insurance.update_all(insurance_account_id: new_account.id) if old_account.loans_as_insurance.any?
        old_account.bank_guarantees_loans.update_all(bank_guarantee_account_id: new_account.id) if old_account.bank_guarantees_loans.any?
      end

      def compute_normalize_number(number)
        # case of sub account on stock, derivative stock
        # must be centralizing normaly
        if number.length > @account_normalizer.standard_length && number[-1] != '0'
          @logger.error("--- number (#{number}) length > #{@account_normalizer.standard_length.to_s} and last number #{number[-1]} is not 0 ---")
          raise StandardError.new("number (#{number}) length > #{@account_normalizer.standard_length.to_s} and last number #{number[-1]} is not 0")
        else
          begin
            @account_padded_normalizer.normalize!(number)
          rescue Accountancy::AccountNumberNormalizer::NormalizationError => e
            @account_normalizer.normalize!(number)
          end
        end
      end
  end
end
