json.array! elements do |phytosanitary_risk|
  json.call(phytosanitary_risk, :product_id, :risk_code, :risk_phrase, :record_checksum)
end
