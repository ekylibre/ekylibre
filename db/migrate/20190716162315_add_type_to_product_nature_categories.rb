class AddTypeToProductNatureCategories < ActiveRecord::Migration
  def change
    add_column :product_nature_categories, :type, :string
    add_column :product_nature_categories, :imported_from, :string

    execute <<-SQL
      UPDATE product_nature_categories AS c1
        SET type = (SELECT type
                    FROM (SELECT category_id, n.type, COUNT(n.type)
                          FROM product_natures AS n
                            INNER JOIN product_nature_categories AS c2
                              ON n.category_id = c2.id
                          GROUP BY category_id, n.type
                          ORDER BY COUNT(n.type) DESC) j
                    WHERE j.category_id = c1.id
                    LIMIT 1);

      UPDATE product_nature_categories AS c1
        SET type = (SELECT type
                    FROM (SELECT type, charge_account_id, COUNT(type)
                          FROM product_nature_categories AS c2
                          WHERE type IS NOT NULL AND charge_account_id IS NOT NULL
                          GROUP BY type, charge_account_id
                          ORDER BY COUNT(type) DESC) j
                    WHERE j.charge_account_id = c1.charge_account_id
                    LIMIT 1)
      WHERE type IS NULL;

      UPDATE product_nature_categories AS c1
        SET type = (SELECT type
                    FROM (SELECT type, product_account_id, COUNT(type)
                          FROM product_nature_categories AS c2
                          WHERE type IS NOT NULL AND product_account_id IS NOT NULL
                          GROUP BY type, product_account_id
                          ORDER BY COUNT(type) DESC) j
                    WHERE j.product_account_id = c1.product_account_id
                    LIMIT 1)
      WHERE type IS NULL;

      UPDATE product_nature_categories
        SET type = 'VariantCategories::ServiceCategory'
      WHERE type IS NULL;

      UPDATE product_nature_categories AS c
        SET type = REPLACE(REPLACE(c.type, 'Types', 'Categories'), 'Type', 'Category');

      UPDATE product_nature_categories
        SET imported_from = 'Nomenclature'
      WHERE reference_name IS NOT NULL
    SQL

    change_column_null :product_nature_categories, :type, false
  end
end
