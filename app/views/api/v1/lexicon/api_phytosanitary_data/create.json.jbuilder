json.set! :data do
  json.partial! 'element_array', locals: { elements: @updated }

  json.array! @removed do |removed|
    json.call(removed, "id")
  end
end
