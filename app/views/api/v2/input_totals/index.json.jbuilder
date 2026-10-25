json.set! :pagination do
  json.call(@pagination, :elements, :page, :per_page, :total_elements, :page_count)
end

json.set! :data do
  json.array! @input_totals do |row|
    json.activity_production row[:activity_production]
    json.input row[:input]
    json.call(row, :quantity_value, :quantity_unit, :conditioning_quantity_value, :conditioning_unit_name,
              :interventions_count, :treated_area_value, :treated_area_unit, :nitrogen_value, :nitrogen_unit)
  end
end
