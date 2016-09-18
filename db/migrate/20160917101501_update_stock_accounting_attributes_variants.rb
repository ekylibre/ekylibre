class UpdateStockAccountingAttributesVariants < ActiveRecord::Migration
  def up
    
    # for each stockable categories in DB
    # puts "--------------------CATEGORIES--------------------".inspect.red
    ProductNatureCategory.all.stockables.where(movement_stock_account: nil).each do |category|
      # puts category.inspect.red
      
      c_items = Nomen::ProductNatureCategory[category.reference_name]
      # puts c_items.inspect.yellow
      
      msa_items = Nomen::Account[c_items.movement_stock_account]
      a = Account.find_or_import_from_nomenclature(msa_items.name)
      # puts a.inspect.green
      execute "UPDATE product_nature_categories SET movement_stock_account_id=#{a.id} WHERE id=#{category.id}"

    end
    
    
    
    # for each stockable variant in DB
    # puts "--------------------VARIANTS----------------------".inspect.red
    
    
    ProductNatureVariant.all.order(:created_at).each_with_index do |variant, index|
      # puts variant.inspect.red
      
      # update existing variant with new numbered method
      if variant.number.blank?
        indice = (index + 1).to_s.rjust(12, '0')
        v_as_numbered = "PNV" + indice
        execute "UPDATE product_nature_variants SET number='#{v_as_numbered}' WHERE id=#{variant.id}" if v_as_numbered
      end
      
      # update variant with stock and movement_account if storable
      if variant.storable?
        # create a new stock_account for current variant
        s = create_unique_account(variant, :stock)
        execute "UPDATE product_nature_variants SET stock_account_id=#{s.id} WHERE id=#{variant.id}" if s
        
        # create a new movement_stock_account for current variant
        ms = create_unique_account(variant, :movement_stock)
        execute "UPDATE product_nature_variants SET movement_stock_account_id=#{ms.id} WHERE id=#{variant.id}" if ms
      end
      
    end
    
  end
  
  def create_unique_account(variant, mode = :stock)
    if mode == :stock || mode == :movement_stock
      account_key = mode.to_s + '_account'
      a = ProductNatureCategory.where(id: variant.category_id).first.send(account_key)
      if a
        # puts a.inspect.yellow
        
        if variant.number
          number = variant.number[-6, 6].rjust(6)
        else
          number = variant.id.to_s
        end
        
        # puts number.inspect.green
        # puts a.number.inspect.green
        
        options = {}
        options[:number] = a.number + number
        options[:name] = a.name + ' [' + variant.name + ']'
        options[:label] = options[:number] + ' - ' + options[:name]
        options[:usages] = a.usages
  
        return ac = Account.create!(options)
      else
        return nil
      end

    end
  end
  
end
