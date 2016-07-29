# Migration generated with nomenclature migration #20160727092830
class UpdateMalusPumilaVarietyName < ActiveRecord::Migration
  def up
    # Merge item varieties#malus_pumila_belle-fille_de_la_creuse into malus_pumila_belle_fille_de_la_creuse
    execute "UPDATE activities SET cultivation_variety='malus_pumila_belle_fille_de_la_creuse' WHERE cultivation_variety='malus_pumila_belle-fille_de_la_creuse'"
    execute "UPDATE activities SET support_variety='malus_pumila_belle_fille_de_la_creuse' WHERE support_variety='malus_pumila_belle-fille_de_la_creuse'"
    execute "UPDATE products SET variety='malus_pumila_belle_fille_de_la_creuse' WHERE variety='malus_pumila_belle-fille_de_la_creuse'"
    execute "UPDATE products SET derivative_of='malus_pumila_belle_fille_de_la_creuse' WHERE derivative_of='malus_pumila_belle-fille_de_la_creuse'"
    execute "UPDATE product_nature_variants SET variety='malus_pumila_belle_fille_de_la_creuse' WHERE variety='malus_pumila_belle-fille_de_la_creuse'"
    execute "UPDATE product_nature_variants SET derivative_of='malus_pumila_belle_fille_de_la_creuse' WHERE derivative_of='malus_pumila_belle-fille_de_la_creuse'"
    execute "UPDATE manure_management_plan_zones SET cultivation_variety='malus_pumila_belle_fille_de_la_creuse' WHERE cultivation_variety='malus_pumila_belle-fille_de_la_creuse'"
    execute "UPDATE product_natures SET variety='malus_pumila_belle_fille_de_la_creuse' WHERE variety='malus_pumila_belle-fille_de_la_creuse'"
    execute "UPDATE product_natures SET derivative_of='malus_pumila_belle_fille_de_la_creuse' WHERE derivative_of='malus_pumila_belle-fille_de_la_creuse'"
  end

  def down
    # Reverse: Merge item varieties#malus_pumila_belle-fille_de_la_creuse into malus_pumila_belle_fille_de_la_creuse
    # Cannot unmerge 'malus_pumila_belle-fille_de_la_creuse' from 'malus_pumila_belle_fille_de_la_creuse' in product_natures#derivative_of
    # Cannot unmerge 'malus_pumila_belle-fille_de_la_creuse' from 'malus_pumila_belle_fille_de_la_creuse' in product_natures#variety
    # Cannot unmerge 'malus_pumila_belle-fille_de_la_creuse' from 'malus_pumila_belle_fille_de_la_creuse' in manure_management_plan_zones#cultivation_variety
    # Cannot unmerge 'malus_pumila_belle-fille_de_la_creuse' from 'malus_pumila_belle_fille_de_la_creuse' in product_nature_variants#derivative_of
    # Cannot unmerge 'malus_pumila_belle-fille_de_la_creuse' from 'malus_pumila_belle_fille_de_la_creuse' in product_nature_variants#variety
    # Cannot unmerge 'malus_pumila_belle-fille_de_la_creuse' from 'malus_pumila_belle_fille_de_la_creuse' in products#derivative_of
    # Cannot unmerge 'malus_pumila_belle-fille_de_la_creuse' from 'malus_pumila_belle_fille_de_la_creuse' in products#variety
    # Cannot unmerge 'malus_pumila_belle-fille_de_la_creuse' from 'malus_pumila_belle_fille_de_la_creuse' in activities#support_variety
    # Cannot unmerge 'malus_pumila_belle-fille_de_la_creuse' from 'malus_pumila_belle_fille_de_la_creuse' in activities#cultivation_variety
  end
end
