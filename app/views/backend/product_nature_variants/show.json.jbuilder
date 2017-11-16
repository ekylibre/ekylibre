json.extract! resource, :id, :name, :unit_name
json.identifiable true if resource.identifiable?
json.depreciable true if resource.depreciable?
json.unitary true if resource.population_counting_unitary?
resource.contractual_prices.each do |contract, price|
  json.set! "price_contract_#{contract.id}", price
end
