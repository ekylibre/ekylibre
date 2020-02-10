json.set! :data do
  json.array! @updated do |phytosanitary_risk|
    json.call(phytosanitary_risk, :product_id, :risk_code, :risk_phrase, :record_checksum)
  end

  json.array! @removed do |removed|
    json.call(removed, "id")
  end
end
