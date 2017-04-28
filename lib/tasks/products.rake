require 'csv'

namespace :products do
  desc 'Change product natures with a CSV file. First column: product nature id, second column : variety to replace, third column: derivative of to replace'
  task change_product_natures: :environment do
    if ENV['TENANT'].blank?
      puts 'You must specify tenant in env variable TENANT'.red
      exit 1
    end
    Ekylibre::Tenant.switch! ENV['TENANT']

    file_name = ENV['FILENAME']
    file_path = Rails.root.join(file_name)

    change_product_attributes(file_path, ProductNature)
  end

  desc 'Change product natures variants with a CSV file. First column: product nature variant id, second column : variety to replace, third column: derivative of to replace'
  task change_product_natures_variants: :environment do
    if ENV['TENANT'].blank?
      puts 'You must specify tenant in env variable TENANT'.red
      exit 1
    end
    Ekylibre::Tenant.switch! ENV['TENANT']

    file_name = ENV['FILENAME']
    file_path = Rails.root.join(file_name)

    change_product_attributes(file_path, ProductNatureVariant)
  end

  def change_product_attributes(file_path, model)
    CSV.foreach(file_path, headers: true) do |row|
      id = row[0].to_s
      variety = row[1].to_s
      derivative_of = row[2].to_s
      next if id.blank? && variety.blank? && derivative_of.blank?

      if id.blank?
        puts 'You must specify a product nature id'
        next 3
      end

      if derivative_of.blank?
        puts 'You must specify a derivative_of'
        next 3
      end

      product_nature = model.find(id)
      derivative_of = Nomen::Variety[derivative_of]
      unless product_nature.update_attributes(variety: variety, derivative_of: derivative_of)
        puts "id: #{id} errors: #{product_nature.errors.messages}"
      end
    end
  end
end
