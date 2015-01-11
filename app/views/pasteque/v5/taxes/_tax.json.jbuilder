json.id Tax.find_by_reference_name(tax.name).id
json.taxCatId Nomen::TaxNatures[tax.nature].name rescue nil
json.label tax.human_name rescue nil
json.startDate tax.started_on rescue nil
json.rate tax.amount/100.0 rescue nil
