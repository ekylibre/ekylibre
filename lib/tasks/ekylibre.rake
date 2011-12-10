# coding: utf-8
STDOUT.sync = true
$stdout.sync = true

namespace :import do

  # $ rake import:isa[COMPANY,FILE]
  desc "Import IsaCompta file in a company"
  task :isa, :company, :file, :needs => :environment do |t, args|
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
