require 'csv'

namespace :accountancy do
  desc 'Change journal entry items account number by another'
  task merge_accounts: :environment do
    if ENV['TENANT'].blank?
      puts 'You must specify tenant in env variable TENANT'.red
      exit 1
    end
    Ekylibre::Tenant.switch! ENV['TENANT']

    if ENV['TARGET_NUMBER'].blank?
      puts 'You must specify target account number in env variable TARGET_NUMBER'.red
      exit 3
    end
    target_account = Account.find_by(number: ENV['TARGET_NUMBER'])
    unless target_account
      puts 'Cannot find target account with number: ' + ENV['TARGET_NUMBER']
      exit 31
    end

    doubles = ENV['ACCOUNT_NUMBERS'].to_s.split(/\s*\,\s*/).map do |number|
      account = Account.find_by(number: number)
      unless account
        puts 'Cannot find account with number: ' + number
        exit 32
      end
      account
    end
    if doubles.empty?
      puts 'You must specify account numbers to replace in env variable ACCOUNT_NUMBER'.red
      exit 2
    end

    doubles.each do |account|
      target_account.merge_with(account)
    end
    puts 'All accounts have been merged.'.green
  end

  desc 'Similar to merge_accounts task but with a CSV file. First column: account number to replace, second column: targetted account'
  task merge_accounts_with_file: :environment do
    if ENV['TENANT'].blank?
      puts 'You must specify tenant in env variable TENANT'.red
      exit 1
    end
    Ekylibre::Tenant.switch! ENV['TENANT']

    file_name = ENV['FILENAME']
    file_path = Rails.root.join(file_name)

    CSV.foreach(file_path, headers: true) do |row|
      double_number = row[0].to_s
      target_number = row[1].to_s
      next if double_number.blank? && target_number.blank?
      if double_number.blank? || target_number.blank?
        puts "Cannot find merge #{double_number.inspect} into #{target_number.inspect}"
        next
      end

      double_account = Account.find_by(number: double_number)
      unless double_account
        puts 'Cannot find account with number: ' + double_number
        exit 40
      end

      target_account = Account.find_by(number: target_number)
      unless target_account
        puts 'Cannot find target account with number: ' + target_number
        exit 41
      end

      target_account.merge_with(double_account)
    end
  end
end
