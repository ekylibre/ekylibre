# Create or updates equipments
Exchanges.add_importer :ekylibre_budgets do |file, w|
    
    
    
    s = Roo::OpenOffice.new(file)
    
    #s.sheets.each do |sheet_name|
      #s.default_sheet = s.sheet(sheet_name)
      s.default_sheet = s.sheets[0]
      puts s.info.inspect.green
      
      w.count = s.last_row
      
      campaign = s.cell('A',2)
      activity_name = s.cell('B',2)
      production_variant_reference_name = s.cell('D',2)
      production_variant_support_reference_name = s.cell('E',2)
      production_indicator_reference_name = s.cell('F',2)
      production_indicator_unit_reference_name = s.cell('G',2)
      
      2.upto(s.last_row) do |row_number|
        r = {
          item_code_variant: s.cell('B',row_number),
          proportion: s.cell('C',row_number),
          support_numbers: s.cell('D',row_number),
          item_quantity: s.cell('E',row_number),
          item_quantity_unity: s.cell('F',row_number),
          item_unit_price_amount: s.cell('G',row_number),
          item_direction: s.cell('H',row_number)
        }
        
        puts r.inspect.red
        
        
      end
      
      
    #end
    
   w.check_point


end
