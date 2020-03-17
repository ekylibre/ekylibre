if @pagination.present?
  json.set! :pagination do
    json.call(@pagination, :elements, :page, :total_elements, :page_count)
  end
end

json.set! :data do
  json.partial! 'element_array', locals: { elements: @data }
end
