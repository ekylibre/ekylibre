# coding: utf-8
STDOUT.sync = true
$stdout.sync = true

namespace :import do

  # $ rake import:isa[COMPANY,FILE]
  desc "Import IsaCompta file in a company"
  # task :isa, :company, :file, :needs => :environment do |t, args|
  task :isa, [:company, :file] => :environment do |t, args|
    if company = Company.find_by_code(args[:company])
      file = args[:file]
      if File.exist?(file)
        Exchanges.import(company, :isa_compta, file, :verbose=>true)
      else
        puts "Unfound file: #{file.inspect}"
      end
    else
      puts "Unfound company: #{args[:company].inspect}"
    end
  end

end


namespace :cpn do

  desc "Drop one company"
  task :drop => :environment do
    code = ENV["code"].to_s.downcase
    Apartment::Database.drop(code)
  end

  desc "Create a new company"
  task :create => :environment do
    code = ENV["code"].to_s.downcase
    demo = ENV["demo"]
    Apartment::Database.create(code)
    Apartment::Migrator.migrate(code)
    Apartment::Database.process(code) do
      username, password = "admin", Time.now.to_i.to_s(36)+rand(100000).to_s(36)
      Company.create_with_data({:code => code}, {:name => username, :password => password, :password_confirmation => password, :first_name => "Admin", :last_name => "STRATOR"}, demo)
      puts ""
      puts ""
      puts "*   There is one administrator account: #{username} / #{password}" 
      puts "*   To complete install please update your hosts file:"
      domain = "#{code}.ekylibre.org"
      puts "*   $ sudo sh -c \"echo '127.0.0.1 #{domain}' >> /etc/hosts\""
      puts "*   Then you can go to http://#{domain}:3000"
    end
  end

  desc "Launch migrations for one company"
  task :migrate => :environment do
    code = ENV["code"].to_s.downcase
    Apartment::Migrator.migrate(code)    
  end

  desc "Rollback migrations for one company"
  task :rollback => :environment do
    code = ENV["code"].to_s.downcase
    Apartment::Migrator.rollback(code, ENV["STEP"])    
  end

end
