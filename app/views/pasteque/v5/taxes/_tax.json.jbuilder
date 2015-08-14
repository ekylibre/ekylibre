reference = Nomen::Tax[tax.reference_name]
json.id tax.id.to_s
json.taxCatId Nomen::TaxNature[reference.nature].name
json.label tax.name
json.startDate reference.started_on.to_time.to_i
json.rate (tax.amount / 100.0).to_f
