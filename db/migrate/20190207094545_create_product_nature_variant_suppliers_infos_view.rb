class CreateProductNatureVariantSuppliersInfosView < ActiveRecord::Migration
  def up
    execute <<-SQL.strip_heredoc
      CREATE VIEW product_nature_variant_suppliers_infos AS
      SELECT total_purchase_infos.full_name AS supplier_name,
             total_purchase_infos.entity_id,
             total_purchase_infos.variant_id,
             total_purchase_infos.ordered_quantity,
             ROUND(total_purchase_infos.total_amount/total_purchase_infos.ordered_quantity, 2) AS average_unit_pretax_amount,
             latest_purchases.unit_pretax_amount AS last_unit_pretax_amount
      FROM (
        SELECT p.supplier_id,
               SUM(pi.quantity) AS ordered_quantity,
               SUM(pi.unit_pretax_amount * pi.quantity) AS total_amount,
               pi.variant_id,
               e.full_name,
               e.id AS entity_id
        FROM purchase_items pi
        INNER JOIN purchases p
          ON pi.purchase_id = p.id
        INNER JOIN entities e
          ON e.id = p.supplier_id
        WHERE p.type = 'PurchaseInvoice'
        GROUP BY p.supplier_id, pi.variant_id, e.full_name, e.id) AS total_purchase_infos
      INNER JOIN (
        SELECT DISTINCT ON (p.supplier_id, pi.variant_id)
               p.supplier_id,
               pi.variant_id,
               pi.unit_pretax_amount AS unit_pretax_amount
        FROM purchase_items pi
        INNER JOIN purchases p
          ON pi.purchase_id = p.id
        WHERE p.type = 'PurchaseInvoice'
        ORDER BY p.supplier_id,
                 pi.variant_id,
                 p.invoiced_at DESC) AS latest_purchases
      ON latest_purchases.supplier_id = total_purchase_infos.supplier_id
      AND latest_purchases.variant_id = total_purchase_infos.variant_id
      WHERE ordered_quantity <> 0;
    SQL
  end

  def down
    execute <<-SQL.strip_heredoc
      DROP VIEW product_nature_variant_suppliers_infos
    SQL
  end
end
