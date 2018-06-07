class AddHourCounterToProductCategories < ActiveRecord::Migration
  def up
    varieties = [:tractor]
    product_nature_names = %i[dumper forklift truck wheel_loader]

    update_by_variety(varieties)
    update_by_name(product_nature_names)
  end

  def down
    varieties = [:tractor]
    product_nature_names = %i[dumper forklift truck wheel_loader]

    update_by_variety(varieties, remove_hour_counter: true)
    update_by_name(product_nature_names, remove_hour_counter: true)
  end

  private

  def update_by_variety(varieties, remove_hour_counter: false)
    product_natures = ProductNature.where(variety: varieties)

    update_hour_counter(product_natures, remove_hour_counter: remove_hour_counter)
  end

  def update_by_name(product_natures_names, remove_hour_counter: false)
    locale = Entity.of_company.language.to_sym

    product_natures_names.each do |product_nature_name|
      translated_name = I18n.t("nomenclatures.product_nature_variants.items.#{product_nature_name}", locale: locale)

      product_natures = ProductNature.where(name: translated_name)
      update_hour_counter(product_natures, remove_hour_counter: remove_hour_counter)
    end
  end

  def update_hour_counter(product_natures, remove_hour_counter: false)
    product_natures.each do |product_nature|
      if remove_hour_counter
        remove_variable_indicator(product_nature, :hour_counter)
      else
        product_nature.variable_indicators_list << :hour_counter
      end

      product_nature.save!
    end
  end

  def remove_variable_indicator(product_nature, variable_indicator)
    variable_indicator_index = product_nature.variable_indicators_list.index(variable_indicator)

    return if variable_indicator_index.nil?

    product_nature.variable_indicators_list.delete_at(variable_indicator_index)
  end
end
