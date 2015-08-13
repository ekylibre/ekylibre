# Migration generated with nomenclature migration #3
class FixHordeum < ActiveRecord::Migration
  def up
    # Change item varieties#hordeum_hibernum with new name hordeum_hexastichum and new parent hordeum_vulgare
    execute "UPDATE activities SET cultivation_variety='hordeum_hexastichum' WHERE cultivation_variety='hordeum_hibernum'"
    execute "UPDATE activities SET support_variety='hordeum_hexastichum' WHERE support_variety='hordeum_hibernum'"
    execute "UPDATE products SET variety='hordeum_hexastichum' WHERE variety='hordeum_hibernum'"
    execute "UPDATE products SET derivative_of='hordeum_hexastichum' WHERE derivative_of='hordeum_hibernum'"
    execute "UPDATE product_nature_variants SET variety='hordeum_hexastichum' WHERE variety='hordeum_hibernum'"
    execute "UPDATE product_nature_variants SET derivative_of='hordeum_hexastichum' WHERE derivative_of='hordeum_hibernum'"
    execute "UPDATE manure_management_plan_zones SET cultivation_variety='hordeum_hexastichum' WHERE cultivation_variety='hordeum_hibernum'"
    execute "UPDATE product_natures SET variety='hordeum_hexastichum' WHERE variety='hordeum_hibernum'"
    execute "UPDATE product_natures SET derivative_of='hordeum_hexastichum' WHERE derivative_of='hordeum_hibernum'"
    # Change item varieties#hordeum_vernum with new name hordeum_distichum and new parent hordeum_vulgare
    execute "UPDATE activities SET cultivation_variety='hordeum_distichum' WHERE cultivation_variety='hordeum_vernum'"
    execute "UPDATE activities SET support_variety='hordeum_distichum' WHERE support_variety='hordeum_vernum'"
    execute "UPDATE products SET variety='hordeum_distichum' WHERE variety='hordeum_vernum'"
    execute "UPDATE products SET derivative_of='hordeum_distichum' WHERE derivative_of='hordeum_vernum'"
    execute "UPDATE product_nature_variants SET variety='hordeum_distichum' WHERE variety='hordeum_vernum'"
    execute "UPDATE product_nature_variants SET derivative_of='hordeum_distichum' WHERE derivative_of='hordeum_vernum'"
    execute "UPDATE manure_management_plan_zones SET cultivation_variety='hordeum_distichum' WHERE cultivation_variety='hordeum_vernum'"
    execute "UPDATE product_natures SET variety='hordeum_distichum' WHERE variety='hordeum_vernum'"
    execute "UPDATE product_natures SET derivative_of='hordeum_distichum' WHERE derivative_of='hordeum_vernum'"
    # Merge item varieties#hordeum_vulgare_hexastichum into hordeum_hexastichum
    execute "UPDATE activities SET cultivation_variety='hordeum_hexastichum' WHERE cultivation_variety='hordeum_vulgare_hexastichum'"
    execute "UPDATE activities SET support_variety='hordeum_hexastichum' WHERE support_variety='hordeum_vulgare_hexastichum'"
    execute "UPDATE products SET variety='hordeum_hexastichum' WHERE variety='hordeum_vulgare_hexastichum'"
    execute "UPDATE products SET derivative_of='hordeum_hexastichum' WHERE derivative_of='hordeum_vulgare_hexastichum'"
    execute "UPDATE product_nature_variants SET variety='hordeum_hexastichum' WHERE variety='hordeum_vulgare_hexastichum'"
    execute "UPDATE product_nature_variants SET derivative_of='hordeum_hexastichum' WHERE derivative_of='hordeum_vulgare_hexastichum'"
    execute "UPDATE manure_management_plan_zones SET cultivation_variety='hordeum_hexastichum' WHERE cultivation_variety='hordeum_vulgare_hexastichum'"
    execute "UPDATE product_natures SET variety='hordeum_hexastichum' WHERE variety='hordeum_vulgare_hexastichum'"
    execute "UPDATE product_natures SET derivative_of='hordeum_hexastichum' WHERE derivative_of='hordeum_vulgare_hexastichum'"
    # Change item varieties#hordeum_hibernum_arturio with new name hordeum_hexastichum_arturio
    execute "UPDATE activities SET cultivation_variety='hordeum_hexastichum_arturio' WHERE cultivation_variety='hordeum_hibernum_arturio'"
    execute "UPDATE activities SET support_variety='hordeum_hexastichum_arturio' WHERE support_variety='hordeum_hibernum_arturio'"
    execute "UPDATE products SET variety='hordeum_hexastichum_arturio' WHERE variety='hordeum_hibernum_arturio'"
    execute "UPDATE products SET derivative_of='hordeum_hexastichum_arturio' WHERE derivative_of='hordeum_hibernum_arturio'"
    execute "UPDATE product_nature_variants SET variety='hordeum_hexastichum_arturio' WHERE variety='hordeum_hibernum_arturio'"
    execute "UPDATE product_nature_variants SET derivative_of='hordeum_hexastichum_arturio' WHERE derivative_of='hordeum_hibernum_arturio'"
    execute "UPDATE manure_management_plan_zones SET cultivation_variety='hordeum_hexastichum_arturio' WHERE cultivation_variety='hordeum_hibernum_arturio'"
    execute "UPDATE product_natures SET variety='hordeum_hexastichum_arturio' WHERE variety='hordeum_hibernum_arturio'"
    execute "UPDATE product_natures SET derivative_of='hordeum_hexastichum_arturio' WHERE derivative_of='hordeum_hibernum_arturio'"
    # Change item varieties#hordeum_hibernum_etincel with new name hordeum_hexastichum_etincel
    execute "UPDATE activities SET cultivation_variety='hordeum_hexastichum_etincel' WHERE cultivation_variety='hordeum_hibernum_etincel'"
    execute "UPDATE activities SET support_variety='hordeum_hexastichum_etincel' WHERE support_variety='hordeum_hibernum_etincel'"
    execute "UPDATE products SET variety='hordeum_hexastichum_etincel' WHERE variety='hordeum_hibernum_etincel'"
    execute "UPDATE products SET derivative_of='hordeum_hexastichum_etincel' WHERE derivative_of='hordeum_hibernum_etincel'"
    execute "UPDATE product_nature_variants SET variety='hordeum_hexastichum_etincel' WHERE variety='hordeum_hibernum_etincel'"
    execute "UPDATE product_nature_variants SET derivative_of='hordeum_hexastichum_etincel' WHERE derivative_of='hordeum_hibernum_etincel'"
    execute "UPDATE manure_management_plan_zones SET cultivation_variety='hordeum_hexastichum_etincel' WHERE cultivation_variety='hordeum_hibernum_etincel'"
    execute "UPDATE product_natures SET variety='hordeum_hexastichum_etincel' WHERE variety='hordeum_hibernum_etincel'"
    execute "UPDATE product_natures SET derivative_of='hordeum_hexastichum_etincel' WHERE derivative_of='hordeum_hibernum_etincel'"
    # Merge item varieties#hordeum_hibernum_cerevisiae_hypoproteinae into hordeum_hibernum_cerevisiae
    execute "UPDATE activities SET cultivation_variety='hordeum_hibernum_cerevisiae' WHERE cultivation_variety='hordeum_hibernum_cerevisiae_hypoproteinae'"
    execute "UPDATE activities SET support_variety='hordeum_hibernum_cerevisiae' WHERE support_variety='hordeum_hibernum_cerevisiae_hypoproteinae'"
    execute "UPDATE products SET variety='hordeum_hibernum_cerevisiae' WHERE variety='hordeum_hibernum_cerevisiae_hypoproteinae'"
    execute "UPDATE products SET derivative_of='hordeum_hibernum_cerevisiae' WHERE derivative_of='hordeum_hibernum_cerevisiae_hypoproteinae'"
    execute "UPDATE product_nature_variants SET variety='hordeum_hibernum_cerevisiae' WHERE variety='hordeum_hibernum_cerevisiae_hypoproteinae'"
    execute "UPDATE product_nature_variants SET derivative_of='hordeum_hibernum_cerevisiae' WHERE derivative_of='hordeum_hibernum_cerevisiae_hypoproteinae'"
    execute "UPDATE manure_management_plan_zones SET cultivation_variety='hordeum_hibernum_cerevisiae' WHERE cultivation_variety='hordeum_hibernum_cerevisiae_hypoproteinae'"
    execute "UPDATE product_natures SET variety='hordeum_hibernum_cerevisiae' WHERE variety='hordeum_hibernum_cerevisiae_hypoproteinae'"
    execute "UPDATE product_natures SET derivative_of='hordeum_hibernum_cerevisiae' WHERE derivative_of='hordeum_hibernum_cerevisiae_hypoproteinae'"
    # Merge item varieties#hordeum_hibernum_cerevisiae into hordeum_hexastichum
    execute "UPDATE activities SET cultivation_variety='hordeum_hexastichum' WHERE cultivation_variety='hordeum_hibernum_cerevisiae'"
    execute "UPDATE activities SET support_variety='hordeum_hexastichum' WHERE support_variety='hordeum_hibernum_cerevisiae'"
    execute "UPDATE products SET variety='hordeum_hexastichum' WHERE variety='hordeum_hibernum_cerevisiae'"
    execute "UPDATE products SET derivative_of='hordeum_hexastichum' WHERE derivative_of='hordeum_hibernum_cerevisiae'"
    execute "UPDATE product_nature_variants SET variety='hordeum_hexastichum' WHERE variety='hordeum_hibernum_cerevisiae'"
    execute "UPDATE product_nature_variants SET derivative_of='hordeum_hexastichum' WHERE derivative_of='hordeum_hibernum_cerevisiae'"
    execute "UPDATE manure_management_plan_zones SET cultivation_variety='hordeum_hexastichum' WHERE cultivation_variety='hordeum_hibernum_cerevisiae'"
    execute "UPDATE product_natures SET variety='hordeum_hexastichum' WHERE variety='hordeum_hibernum_cerevisiae'"
    execute "UPDATE product_natures SET derivative_of='hordeum_hexastichum' WHERE derivative_of='hordeum_hibernum_cerevisiae'"
    # Change item varieties#hordeum_vernum_traveler with new name hordeum_distichum_traveler
    execute "UPDATE activities SET cultivation_variety='hordeum_distichum_traveler' WHERE cultivation_variety='hordeum_vernum_traveler'"
    execute "UPDATE activities SET support_variety='hordeum_distichum_traveler' WHERE support_variety='hordeum_vernum_traveler'"
    execute "UPDATE products SET variety='hordeum_distichum_traveler' WHERE variety='hordeum_vernum_traveler'"
    execute "UPDATE products SET derivative_of='hordeum_distichum_traveler' WHERE derivative_of='hordeum_vernum_traveler'"
    execute "UPDATE product_nature_variants SET variety='hordeum_distichum_traveler' WHERE variety='hordeum_vernum_traveler'"
    execute "UPDATE product_nature_variants SET derivative_of='hordeum_distichum_traveler' WHERE derivative_of='hordeum_vernum_traveler'"
    execute "UPDATE manure_management_plan_zones SET cultivation_variety='hordeum_distichum_traveler' WHERE cultivation_variety='hordeum_vernum_traveler'"
    execute "UPDATE product_natures SET variety='hordeum_distichum_traveler' WHERE variety='hordeum_vernum_traveler'"
    execute "UPDATE product_natures SET derivative_of='hordeum_distichum_traveler' WHERE derivative_of='hordeum_vernum_traveler'"
    # Merge item varieties#hordeum_vernum_hypoproteinae into hordeum_distichum
    execute "UPDATE activities SET cultivation_variety='hordeum_distichum' WHERE cultivation_variety='hordeum_vernum_hypoproteinae'"
    execute "UPDATE activities SET support_variety='hordeum_distichum' WHERE support_variety='hordeum_vernum_hypoproteinae'"
    execute "UPDATE products SET variety='hordeum_distichum' WHERE variety='hordeum_vernum_hypoproteinae'"
    execute "UPDATE products SET derivative_of='hordeum_distichum' WHERE derivative_of='hordeum_vernum_hypoproteinae'"
    execute "UPDATE product_nature_variants SET variety='hordeum_distichum' WHERE variety='hordeum_vernum_hypoproteinae'"
    execute "UPDATE product_nature_variants SET derivative_of='hordeum_distichum' WHERE derivative_of='hordeum_vernum_hypoproteinae'"
    execute "UPDATE manure_management_plan_zones SET cultivation_variety='hordeum_distichum' WHERE cultivation_variety='hordeum_vernum_hypoproteinae'"
    execute "UPDATE product_natures SET variety='hordeum_distichum' WHERE variety='hordeum_vernum_hypoproteinae'"
    execute "UPDATE product_natures SET derivative_of='hordeum_distichum' WHERE derivative_of='hordeum_vernum_hypoproteinae'"
  end

  def down
    # Reverse: Merge item varieties#hordeum_vernum_hypoproteinae into hordeum_distichum
    # Cannot unmerge 'hordeum_vernum_hypoproteinae' from 'hordeum_distichum' in product_natures#derivative_of
    # Cannot unmerge 'hordeum_vernum_hypoproteinae' from 'hordeum_distichum' in product_natures#variety
    # Cannot unmerge 'hordeum_vernum_hypoproteinae' from 'hordeum_distichum' in manure_management_plan_zones#cultivation_variety
    # Cannot unmerge 'hordeum_vernum_hypoproteinae' from 'hordeum_distichum' in product_nature_variants#derivative_of
    # Cannot unmerge 'hordeum_vernum_hypoproteinae' from 'hordeum_distichum' in product_nature_variants#variety
    # Cannot unmerge 'hordeum_vernum_hypoproteinae' from 'hordeum_distichum' in products#derivative_of
    # Cannot unmerge 'hordeum_vernum_hypoproteinae' from 'hordeum_distichum' in products#variety
    # Cannot unmerge 'hordeum_vernum_hypoproteinae' from 'hordeum_distichum' in activities#support_variety
    # Cannot unmerge 'hordeum_vernum_hypoproteinae' from 'hordeum_distichum' in activities#cultivation_variety
    # Reverse: Change item varieties#hordeum_vernum_traveler with new name hordeum_distichum_traveler
    execute "UPDATE product_natures SET derivative_of='hordeum_vernum_traveler' WHERE derivative_of='hordeum_distichum_traveler'"
    execute "UPDATE product_natures SET variety='hordeum_vernum_traveler' WHERE variety='hordeum_distichum_traveler'"
    execute "UPDATE manure_management_plan_zones SET cultivation_variety='hordeum_vernum_traveler' WHERE cultivation_variety='hordeum_distichum_traveler'"
    execute "UPDATE product_nature_variants SET derivative_of='hordeum_vernum_traveler' WHERE derivative_of='hordeum_distichum_traveler'"
    execute "UPDATE product_nature_variants SET variety='hordeum_vernum_traveler' WHERE variety='hordeum_distichum_traveler'"
    execute "UPDATE products SET derivative_of='hordeum_vernum_traveler' WHERE derivative_of='hordeum_distichum_traveler'"
    execute "UPDATE products SET variety='hordeum_vernum_traveler' WHERE variety='hordeum_distichum_traveler'"
    execute "UPDATE activities SET support_variety='hordeum_vernum_traveler' WHERE support_variety='hordeum_distichum_traveler'"
    execute "UPDATE activities SET cultivation_variety='hordeum_vernum_traveler' WHERE cultivation_variety='hordeum_distichum_traveler'"
    # Reverse: Merge item varieties#hordeum_hibernum_cerevisiae into hordeum_hexastichum
    # Cannot unmerge 'hordeum_hibernum_cerevisiae' from 'hordeum_hexastichum' in product_natures#derivative_of
    # Cannot unmerge 'hordeum_hibernum_cerevisiae' from 'hordeum_hexastichum' in product_natures#variety
    # Cannot unmerge 'hordeum_hibernum_cerevisiae' from 'hordeum_hexastichum' in manure_management_plan_zones#cultivation_variety
    # Cannot unmerge 'hordeum_hibernum_cerevisiae' from 'hordeum_hexastichum' in product_nature_variants#derivative_of
    # Cannot unmerge 'hordeum_hibernum_cerevisiae' from 'hordeum_hexastichum' in product_nature_variants#variety
    # Cannot unmerge 'hordeum_hibernum_cerevisiae' from 'hordeum_hexastichum' in products#derivative_of
    # Cannot unmerge 'hordeum_hibernum_cerevisiae' from 'hordeum_hexastichum' in products#variety
    # Cannot unmerge 'hordeum_hibernum_cerevisiae' from 'hordeum_hexastichum' in activities#support_variety
    # Cannot unmerge 'hordeum_hibernum_cerevisiae' from 'hordeum_hexastichum' in activities#cultivation_variety
    # Reverse: Merge item varieties#hordeum_hibernum_cerevisiae_hypoproteinae into hordeum_hibernum_cerevisiae
    # Cannot unmerge 'hordeum_hibernum_cerevisiae_hypoproteinae' from 'hordeum_hibernum_cerevisiae' in product_natures#derivative_of
    # Cannot unmerge 'hordeum_hibernum_cerevisiae_hypoproteinae' from 'hordeum_hibernum_cerevisiae' in product_natures#variety
    # Cannot unmerge 'hordeum_hibernum_cerevisiae_hypoproteinae' from 'hordeum_hibernum_cerevisiae' in manure_management_plan_zones#cultivation_variety
    # Cannot unmerge 'hordeum_hibernum_cerevisiae_hypoproteinae' from 'hordeum_hibernum_cerevisiae' in product_nature_variants#derivative_of
    # Cannot unmerge 'hordeum_hibernum_cerevisiae_hypoproteinae' from 'hordeum_hibernum_cerevisiae' in product_nature_variants#variety
    # Cannot unmerge 'hordeum_hibernum_cerevisiae_hypoproteinae' from 'hordeum_hibernum_cerevisiae' in products#derivative_of
    # Cannot unmerge 'hordeum_hibernum_cerevisiae_hypoproteinae' from 'hordeum_hibernum_cerevisiae' in products#variety
    # Cannot unmerge 'hordeum_hibernum_cerevisiae_hypoproteinae' from 'hordeum_hibernum_cerevisiae' in activities#support_variety
    # Cannot unmerge 'hordeum_hibernum_cerevisiae_hypoproteinae' from 'hordeum_hibernum_cerevisiae' in activities#cultivation_variety
    # Reverse: Change item varieties#hordeum_hibernum_etincel with new name hordeum_hexastichum_etincel
    execute "UPDATE product_natures SET derivative_of='hordeum_hibernum_etincel' WHERE derivative_of='hordeum_hexastichum_etincel'"
    execute "UPDATE product_natures SET variety='hordeum_hibernum_etincel' WHERE variety='hordeum_hexastichum_etincel'"
    execute "UPDATE manure_management_plan_zones SET cultivation_variety='hordeum_hibernum_etincel' WHERE cultivation_variety='hordeum_hexastichum_etincel'"
    execute "UPDATE product_nature_variants SET derivative_of='hordeum_hibernum_etincel' WHERE derivative_of='hordeum_hexastichum_etincel'"
    execute "UPDATE product_nature_variants SET variety='hordeum_hibernum_etincel' WHERE variety='hordeum_hexastichum_etincel'"
    execute "UPDATE products SET derivative_of='hordeum_hibernum_etincel' WHERE derivative_of='hordeum_hexastichum_etincel'"
    execute "UPDATE products SET variety='hordeum_hibernum_etincel' WHERE variety='hordeum_hexastichum_etincel'"
    execute "UPDATE activities SET support_variety='hordeum_hibernum_etincel' WHERE support_variety='hordeum_hexastichum_etincel'"
    execute "UPDATE activities SET cultivation_variety='hordeum_hibernum_etincel' WHERE cultivation_variety='hordeum_hexastichum_etincel'"
    # Reverse: Change item varieties#hordeum_hibernum_arturio with new name hordeum_hexastichum_arturio
    execute "UPDATE product_natures SET derivative_of='hordeum_hibernum_arturio' WHERE derivative_of='hordeum_hexastichum_arturio'"
    execute "UPDATE product_natures SET variety='hordeum_hibernum_arturio' WHERE variety='hordeum_hexastichum_arturio'"
    execute "UPDATE manure_management_plan_zones SET cultivation_variety='hordeum_hibernum_arturio' WHERE cultivation_variety='hordeum_hexastichum_arturio'"
    execute "UPDATE product_nature_variants SET derivative_of='hordeum_hibernum_arturio' WHERE derivative_of='hordeum_hexastichum_arturio'"
    execute "UPDATE product_nature_variants SET variety='hordeum_hibernum_arturio' WHERE variety='hordeum_hexastichum_arturio'"
    execute "UPDATE products SET derivative_of='hordeum_hibernum_arturio' WHERE derivative_of='hordeum_hexastichum_arturio'"
    execute "UPDATE products SET variety='hordeum_hibernum_arturio' WHERE variety='hordeum_hexastichum_arturio'"
    execute "UPDATE activities SET support_variety='hordeum_hibernum_arturio' WHERE support_variety='hordeum_hexastichum_arturio'"
    execute "UPDATE activities SET cultivation_variety='hordeum_hibernum_arturio' WHERE cultivation_variety='hordeum_hexastichum_arturio'"
    # Reverse: Merge item varieties#hordeum_vulgare_hexastichum into hordeum_hexastichum
    # Cannot unmerge 'hordeum_vulgare_hexastichum' from 'hordeum_hexastichum' in product_natures#derivative_of
    # Cannot unmerge 'hordeum_vulgare_hexastichum' from 'hordeum_hexastichum' in product_natures#variety
    # Cannot unmerge 'hordeum_vulgare_hexastichum' from 'hordeum_hexastichum' in manure_management_plan_zones#cultivation_variety
    # Cannot unmerge 'hordeum_vulgare_hexastichum' from 'hordeum_hexastichum' in product_nature_variants#derivative_of
    # Cannot unmerge 'hordeum_vulgare_hexastichum' from 'hordeum_hexastichum' in product_nature_variants#variety
    # Cannot unmerge 'hordeum_vulgare_hexastichum' from 'hordeum_hexastichum' in products#derivative_of
    # Cannot unmerge 'hordeum_vulgare_hexastichum' from 'hordeum_hexastichum' in products#variety
    # Cannot unmerge 'hordeum_vulgare_hexastichum' from 'hordeum_hexastichum' in activities#support_variety
    # Cannot unmerge 'hordeum_vulgare_hexastichum' from 'hordeum_hexastichum' in activities#cultivation_variety
    # Reverse: Change item varieties#hordeum_vernum with new name hordeum_distichum and new parent hordeum_vulgare
    execute "UPDATE product_natures SET derivative_of='hordeum_vernum' WHERE derivative_of='hordeum_distichum'"
    execute "UPDATE product_natures SET variety='hordeum_vernum' WHERE variety='hordeum_distichum'"
    execute "UPDATE manure_management_plan_zones SET cultivation_variety='hordeum_vernum' WHERE cultivation_variety='hordeum_distichum'"
    execute "UPDATE product_nature_variants SET derivative_of='hordeum_vernum' WHERE derivative_of='hordeum_distichum'"
    execute "UPDATE product_nature_variants SET variety='hordeum_vernum' WHERE variety='hordeum_distichum'"
    execute "UPDATE products SET derivative_of='hordeum_vernum' WHERE derivative_of='hordeum_distichum'"
    execute "UPDATE products SET variety='hordeum_vernum' WHERE variety='hordeum_distichum'"
    execute "UPDATE activities SET support_variety='hordeum_vernum' WHERE support_variety='hordeum_distichum'"
    execute "UPDATE activities SET cultivation_variety='hordeum_vernum' WHERE cultivation_variety='hordeum_distichum'"
    # Reverse: Change item varieties#hordeum_hibernum with new name hordeum_hexastichum and new parent hordeum_vulgare
    execute "UPDATE product_natures SET derivative_of='hordeum_hibernum' WHERE derivative_of='hordeum_hexastichum'"
    execute "UPDATE product_natures SET variety='hordeum_hibernum' WHERE variety='hordeum_hexastichum'"
    execute "UPDATE manure_management_plan_zones SET cultivation_variety='hordeum_hibernum' WHERE cultivation_variety='hordeum_hexastichum'"
    execute "UPDATE product_nature_variants SET derivative_of='hordeum_hibernum' WHERE derivative_of='hordeum_hexastichum'"
    execute "UPDATE product_nature_variants SET variety='hordeum_hibernum' WHERE variety='hordeum_hexastichum'"
    execute "UPDATE products SET derivative_of='hordeum_hibernum' WHERE derivative_of='hordeum_hexastichum'"
    execute "UPDATE products SET variety='hordeum_hibernum' WHERE variety='hordeum_hexastichum'"
    execute "UPDATE activities SET support_variety='hordeum_hibernum' WHERE support_variety='hordeum_hexastichum'"
    execute "UPDATE activities SET cultivation_variety='hordeum_hibernum' WHERE cultivation_variety='hordeum_hexastichum'"
  end
end
