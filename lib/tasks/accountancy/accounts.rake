require 'csv'
require_relative './accountancy'

namespace :accountancy do
  desc 'Change journal entry items account number by another'
  task merge_accounts: :environment do
    tenant = ENV['TENANT']
    account_numbers_to_replace = ENV['ACCOUNT_NUMBERS']
    target_account_number = ENV['TARGET_NUMBER']

    if tenant.nil?
      puts "You must specify tenant in params".red
      exit
    end

    if account_numbers_to_replace.nil?
      puts "You must specify account numbers to replace in params".red
      exit
    end

    if target_account_number.nil?
      puts "You must specify target account number in params".red
      exit
    end

    Ekylibre::Tenant::switch! tenant

    puts "Switch on tenant #{Ekylibre::Tenant::current}".yellow

    account_numbers = account_numbers_to_replace.split(',')

    begin

      account_numbers.each do |account_number|
        Accountancy.merge_accounts(account_number_to_replace: account_number, target_number_account: target_account_number)
      end
    rescue ActiveRecord::StatementInvalid
    end
  end

  desc 'Similar to merge_accounts task but with a CSV file. First column : account number to replace, second column : targetted account.'
  task merge_accounts_with_file: :environment do
    file_name = ENV['FILENAME']
    file_path = Rails.root.join(file_name)

    tenant = ENV['TENANT']

    if tenant.nil?
      puts "You must specify tenant in params".red
      exit
    end

    Ekylibre::Tenant::switch! tenant

    puts "Switch on tenant #{Ekylibre::Tenant::current}".yellow

    CSV.foreach(file_path, :headers => true) do |row|
      row_values = row.to_hash.values
      account_number_to_replace = row_values.first
      target_number_account = row_values.last

      if account_number_to_replace.nil?
        puts "You must specify account numbers to replace in CSV file".red
        next
      end

      if target_number_account.nil?
        puts "You must specify target account number in CSV file".red
        next
      end

      begin
        Accountancy.merge_accounts(account_number_to_replace: account_number_to_replace, target_number_account: target_number_account)
      rescue ActiveRecord::StatementInvalid
      end
    end
  end
end
