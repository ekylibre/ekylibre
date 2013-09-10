class AddReduction < ActiveRecord::Migration
  def self.up

    add_column :subscription_natures, :reduction_rate, :decimal, :precision=>8, :scale=>2
    add_column :subscription_natures, :entity_link_nature_id, :integer
    add_index :subscription_natures, :entity_link_nature_id

    add_column :sale_order_lines, :reduction_origin_id, :integer,  :references=>:sale_order_lines, :on_delete=>:cascade, :on_update=>:cascade
    add_column :sale_order_lines, :label, :text
    add_index :sale_order_lines, :reduction_origin_id

    add_column :documents, :nature_code, :string
    for template in connection.select_all("SELECT n.code AS code, t.id AS id FROM #{quoted_table_name(:document_templates)} AS t JOIN #{quoted_table_name(:document_natures)} AS n ON (n.id=t.nature_id)")
      execute "UPDATE #{quoted_table_name(:documents)} SET nature_code = '#{template['code'].gsub(/\'/,"''")}' WHERE template_id=#{template['id']}"
    end
  end

  def self.down
    remove_column :documents, :nature_code

    remove_column :sale_order_lines, :label
    remove_column :sale_order_lines, :reduction_origin_id

    remove_column :subscription_natures, :entity_link_nature_id
    remove_column :subscription_natures, :reduction_rate
  end
end
