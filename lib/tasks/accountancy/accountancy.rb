class Accountancy

  class << self
    
    def merge_accounts(account_number_to_replace: nil, target_number_account: nil)

       target_account = Account.find_by_number(target_number_account)

       if target_account.nil?
         puts "The targetted account with number #{target_number_account} not exist".red
         return 
       end
       
       account_to_replace = Account.find_by_number(account_number_to_replace)
       
       if account_to_replace.nil?
         puts "The account to replace number #{account_number_to_replace} not exist".red
         return 
       else
       
         journal_entry = JournalEntryItem.where(account_id: account_to_replace.id)
         journal_entry.update_all(account_id: target_account.id)
         puts "The account with #{account_number_to_replace} number is merged".green
       end 
    end
  end
end
