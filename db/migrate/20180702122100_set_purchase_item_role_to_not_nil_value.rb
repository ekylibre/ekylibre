class SetPurchaseItemRoleToNotNilValue < ActiveRecord::Migration
  def change
    reversible do |dir|
      dir.up do
        execute set_purchase_items_role_to_service
        execute set_purchase_items_role_to_merchandise
      end

      dir.down do
        execute set_purchase_items_role_to_null
      end
    end
  end

  def set_purchase_items_role_to_service
    <<-SQL
	    UPDATE purchase_items pi
		  SET role = 'service'
		  WHERE  pi.role IS NULL
	 			AND pi.variant_id IN (
		 		SELECT product_nature_variants.id
		 		FROM product_nature_variants
		 		WHERE product_nature_variants.variety = 'service'
	 		)
	  SQL
  end

  def set_purchase_items_role_to_merchandise
    <<-SQL
	    UPDATE purchase_items pi
		  SET role = 'merchandise'
		  WHERE  pi.role IS NULL
	 			AND pi.variant_id IN (
		 		SELECT product_nature_variants.id
		 		FROM product_nature_variants
		 		WHERE product_nature_variants.category_id IN (
		 			SELECT product_nature_categories.id
		 			FROM product_nature_categories
		 			WHERE product_nature_categories.purchasable = true)
				AND product_nature_variants.variety <> 'service'
	 		)
	  SQL
  end

  def set_purchase_items_role_to_null
    <<-SQL
	    UPDATE purchase_items pi
		  SET role = NULL
	  SQL
  end
end
