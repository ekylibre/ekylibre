json.array! elements do |cropset|
  json.call(cropset, :id, :name, :label, :crop_names, :crop_labels, :record_checksum)
end