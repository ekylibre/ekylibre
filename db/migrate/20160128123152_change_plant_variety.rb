# Migration generated with nomenclature migration #20160115090243
class ChangePlantVariety < ActiveRecord::Migration
  def up
    # Change item varieties#brassica_pringlea with {:name=>"pringlea_antiscorbutica", :parent=>"brassicaceae"}
    execute "UPDATE activities SET cultivation_variety='pringlea_antiscorbutica' WHERE cultivation_variety='brassica_pringlea'"
    execute "UPDATE activities SET support_variety='pringlea_antiscorbutica' WHERE support_variety='brassica_pringlea'"
    execute "UPDATE products SET variety='pringlea_antiscorbutica' WHERE variety='brassica_pringlea'"
    execute "UPDATE products SET derivative_of='pringlea_antiscorbutica' WHERE derivative_of='brassica_pringlea'"
    execute "UPDATE product_nature_variants SET variety='pringlea_antiscorbutica' WHERE variety='brassica_pringlea'"
    execute "UPDATE product_nature_variants SET derivative_of='pringlea_antiscorbutica' WHERE derivative_of='brassica_pringlea'"
    execute "UPDATE manure_management_plan_zones SET cultivation_variety='pringlea_antiscorbutica' WHERE cultivation_variety='brassica_pringlea'"
    execute "UPDATE product_natures SET variety='pringlea_antiscorbutica' WHERE variety='brassica_pringlea'"
    execute "UPDATE product_natures SET derivative_of='pringlea_antiscorbutica' WHERE derivative_of='brassica_pringlea'"
    # Change item varieties#brassica_rapa_annua with {:name=>"brassica_rapa_oleifera_annua", :parent=>"brassica_rapa_oleifera", :itis_tsn=>"23063"}
    execute "UPDATE activities SET cultivation_variety='brassica_rapa_oleifera_annua' WHERE cultivation_variety='brassica_rapa_annua'"
    execute "UPDATE activities SET support_variety='brassica_rapa_oleifera_annua' WHERE support_variety='brassica_rapa_annua'"
    execute "UPDATE products SET variety='brassica_rapa_oleifera_annua' WHERE variety='brassica_rapa_annua'"
    execute "UPDATE products SET derivative_of='brassica_rapa_oleifera_annua' WHERE derivative_of='brassica_rapa_annua'"
    execute "UPDATE product_nature_variants SET variety='brassica_rapa_oleifera_annua' WHERE variety='brassica_rapa_annua'"
    execute "UPDATE product_nature_variants SET derivative_of='brassica_rapa_oleifera_annua' WHERE derivative_of='brassica_rapa_annua'"
    execute "UPDATE manure_management_plan_zones SET cultivation_variety='brassica_rapa_oleifera_annua' WHERE cultivation_variety='brassica_rapa_annua'"
    execute "UPDATE product_natures SET variety='brassica_rapa_oleifera_annua' WHERE variety='brassica_rapa_annua'"
    execute "UPDATE product_natures SET derivative_of='brassica_rapa_oleifera_annua' WHERE derivative_of='brassica_rapa_annua'"
    # Change item varieties#brassica_rapa_biennis with {:name=>"brassica_rapa_oleifera_biennis", :parent=>"brassica_rapa_oleifera", :itis_tsn=>"23063"}
    execute "UPDATE activities SET cultivation_variety='brassica_rapa_oleifera_biennis' WHERE cultivation_variety='brassica_rapa_biennis'"
    execute "UPDATE activities SET support_variety='brassica_rapa_oleifera_biennis' WHERE support_variety='brassica_rapa_biennis'"
    execute "UPDATE products SET variety='brassica_rapa_oleifera_biennis' WHERE variety='brassica_rapa_biennis'"
    execute "UPDATE products SET derivative_of='brassica_rapa_oleifera_biennis' WHERE derivative_of='brassica_rapa_biennis'"
    execute "UPDATE product_nature_variants SET variety='brassica_rapa_oleifera_biennis' WHERE variety='brassica_rapa_biennis'"
    execute "UPDATE product_nature_variants SET derivative_of='brassica_rapa_oleifera_biennis' WHERE derivative_of='brassica_rapa_biennis'"
    execute "UPDATE manure_management_plan_zones SET cultivation_variety='brassica_rapa_oleifera_biennis' WHERE cultivation_variety='brassica_rapa_biennis'"
    execute "UPDATE product_natures SET variety='brassica_rapa_oleifera_biennis' WHERE variety='brassica_rapa_biennis'"
    execute "UPDATE product_natures SET derivative_of='brassica_rapa_oleifera_biennis' WHERE derivative_of='brassica_rapa_biennis'"
  end

  def down
    # Reverse: Change item varieties#brassica_rapa_biennis with {:name=>"brassica_rapa_oleifera_biennis", :parent=>"brassica_rapa_oleifera", :itis_tsn=>"23063"}
    execute "UPDATE product_natures SET derivative_of='brassica_rapa_biennis' WHERE derivative_of='brassica_rapa_oleifera_biennis'"
    execute "UPDATE product_natures SET variety='brassica_rapa_biennis' WHERE variety='brassica_rapa_oleifera_biennis'"
    execute "UPDATE manure_management_plan_zones SET cultivation_variety='brassica_rapa_biennis' WHERE cultivation_variety='brassica_rapa_oleifera_biennis'"
    execute "UPDATE product_nature_variants SET derivative_of='brassica_rapa_biennis' WHERE derivative_of='brassica_rapa_oleifera_biennis'"
    execute "UPDATE product_nature_variants SET variety='brassica_rapa_biennis' WHERE variety='brassica_rapa_oleifera_biennis'"
    execute "UPDATE products SET derivative_of='brassica_rapa_biennis' WHERE derivative_of='brassica_rapa_oleifera_biennis'"
    execute "UPDATE products SET variety='brassica_rapa_biennis' WHERE variety='brassica_rapa_oleifera_biennis'"
    execute "UPDATE activities SET support_variety='brassica_rapa_biennis' WHERE support_variety='brassica_rapa_oleifera_biennis'"
    execute "UPDATE activities SET cultivation_variety='brassica_rapa_biennis' WHERE cultivation_variety='brassica_rapa_oleifera_biennis'"
    # Reverse: Change item varieties#brassica_rapa_annua with {:name=>"brassica_rapa_oleifera_annua", :parent=>"brassica_rapa_oleifera", :itis_tsn=>"23063"}
    execute "UPDATE product_natures SET derivative_of='brassica_rapa_annua' WHERE derivative_of='brassica_rapa_oleifera_annua'"
    execute "UPDATE product_natures SET variety='brassica_rapa_annua' WHERE variety='brassica_rapa_oleifera_annua'"
    execute "UPDATE manure_management_plan_zones SET cultivation_variety='brassica_rapa_annua' WHERE cultivation_variety='brassica_rapa_oleifera_annua'"
    execute "UPDATE product_nature_variants SET derivative_of='brassica_rapa_annua' WHERE derivative_of='brassica_rapa_oleifera_annua'"
    execute "UPDATE product_nature_variants SET variety='brassica_rapa_annua' WHERE variety='brassica_rapa_oleifera_annua'"
    execute "UPDATE products SET derivative_of='brassica_rapa_annua' WHERE derivative_of='brassica_rapa_oleifera_annua'"
    execute "UPDATE products SET variety='brassica_rapa_annua' WHERE variety='brassica_rapa_oleifera_annua'"
    execute "UPDATE activities SET support_variety='brassica_rapa_annua' WHERE support_variety='brassica_rapa_oleifera_annua'"
    execute "UPDATE activities SET cultivation_variety='brassica_rapa_annua' WHERE cultivation_variety='brassica_rapa_oleifera_annua'"
    # Reverse: Change item varieties#brassica_pringlea with {:name=>"pringlea_antiscorbutica", :parent=>"brassicaceae"}
    execute "UPDATE product_natures SET derivative_of='brassica_pringlea' WHERE derivative_of='pringlea_antiscorbutica'"
    execute "UPDATE product_natures SET variety='brassica_pringlea' WHERE variety='pringlea_antiscorbutica'"
    execute "UPDATE manure_management_plan_zones SET cultivation_variety='brassica_pringlea' WHERE cultivation_variety='pringlea_antiscorbutica'"
    execute "UPDATE product_nature_variants SET derivative_of='brassica_pringlea' WHERE derivative_of='pringlea_antiscorbutica'"
    execute "UPDATE product_nature_variants SET variety='brassica_pringlea' WHERE variety='pringlea_antiscorbutica'"
    execute "UPDATE products SET derivative_of='brassica_pringlea' WHERE derivative_of='pringlea_antiscorbutica'"
    execute "UPDATE products SET variety='brassica_pringlea' WHERE variety='pringlea_antiscorbutica'"
    execute "UPDATE activities SET support_variety='brassica_pringlea' WHERE support_variety='pringlea_antiscorbutica'"
    execute "UPDATE activities SET cultivation_variety='brassica_pringlea' WHERE cultivation_variety='pringlea_antiscorbutica'"
  end
end
