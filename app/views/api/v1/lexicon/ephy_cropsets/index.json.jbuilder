json.set! :data do
  json.array! @updated do |cropset|
    json.call(cropset, :id, :name, :label, :crop_names, :crop_labels, :record_checksum)
  end

  json.array! @removed do |removed|
    json.call(removed, "id")
  end
end
