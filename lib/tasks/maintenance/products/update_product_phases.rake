# Tenant tasks
namespace :maintenance do
  namespace :products do
    desc 'Update all products phases'
    task update_product_phases: :environment do
      tenant = ENV['TENANT']

      raise 'Need TENANT variable' unless tenant

      puts "Switch to tenant #{tenant}"
      Ekylibre::Tenant.switch(tenant) do
        products_to_update = products_with_phases_to_update

        update_phases(products_to_update)
      end
    end

    desc 'Count all products where phases are not updated'
    task count_products_with_phases_to_update: :environment do
      tenant = ENV['TENANT']

      raise 'Need TENANT variable' unless tenant

      puts "Switch to tenant #{tenant}"
      Ekylibre::Tenant.switch(tenant) do
        products_to_update = products_with_phases_to_update

        puts "There are #{ products_to_update.count } products to update"
      end
    end

    def products_with_phases_to_update
      Product
        .joins(:phases)
        .where('product_phases.created_at =
               (SELECT MAX(product_phases.created_at)
                FROM product_phases
                WHERE product_phases.product_id = products.id)')
        .where('products.variant_id != product_phases.variant_id
                OR products.nature_id != product_phases.nature_id
                OR products.category_id != product_phases.category_id')
    end

    def update_phases(products_to_update)
      products_to_update.each do |product|
        variant = product.variant
        product_phases = product.phases.where(product_id: product.id,
                                              variant_id: variant.id,
                                              nature_id: variant.nature.id,
                                              category_id: variant.category.id)

        next if product_phases.any?

        build_new_phase(product)
      end
    end

    def build_new_phase(product)
      variant = product.variant

      product.phases.build(
        product_id: product.id,
        variant_id: variant.id,
        category_id: variant.category.id,
        nature_id: variant.nature.id
      )

      product.save(validate: false)
    end
  end
end
