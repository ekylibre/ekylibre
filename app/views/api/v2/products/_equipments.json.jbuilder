json.call(product, :id, :name, :number, :variety, :born_at, :dead_at, :abilities, :work_number, :derivative_of)
json.has_hour_counter product.variable_indicators.include?(:hour_counter)

json.container_name product.container.present? ? product.container.name : ""
