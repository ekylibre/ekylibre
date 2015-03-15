class AddQuantifierForProductionSupports < ActiveRecord::Migration
  FAMILIES = {
    exploitation: {},
    accountancy: {},
    administrative: {},
    sales: {},
    purchases: {},
    stocks: {},
    processing: {},
    service: {},
    vegetal_crops:  { support_variety: :cultivable_zone, cultivation_variety: :plant},
    animal_farming: { support_variety: :animal_group, cultivation_variety: :animal},
    maintenance:    { cultivation_variety: :equipment},
    field_crops:                   { support_variety: :cultivable_zone, cultivation_variety: :plant},
    market_garden_crops:           { support_variety: :cultivable_zone, cultivation_variety: :plant},
    fruits_crops:                  { support_variety: :cultivable_zone, cultivation_variety: :plant},
    arboriculture:                 { support_variety: :cultivable_zone, cultivation_variety: :plant},
    aromatic_and_medicinal_plants: { support_variety: :cultivable_zone, cultivation_variety: :plant},
    orchard_crops:                 { support_variety: :cultivable_zone, cultivation_variety: :plant},
    vines:                         { support_variety: :cultivable_zone, cultivation_variety: :vitis},
    cereal_crops:  { support_variety: :cultivable_zone, cultivation_variety: :poaceae},
    oilseed_crops: { support_variety: :cultivable_zone, cultivation_variety: :plant},
    protein_crops: { support_variety: :cultivable_zone, cultivation_variety: :plant},
    potato_crops:  { support_variety: :cultivable_zone, cultivation_variety: :solanum_tuberosum},
    beet_crops:    { support_variety: :cultivable_zone, cultivation_variety: :beta},
    hemp_crops:    { support_variety: :cultivable_zone, cultivation_variety: :cannabaceae},
    fallow_land:   { support_variety: :cultivable_zone, cultivation_variety: :plant},
    fodder_crops:  { support_variety: :cultivable_zone, cultivation_variety: :plant},
    meadow:        { support_variety: :cultivable_zone, cultivation_variety: :plant},
    poaceae_crops:            { support_variety: :cultivable_zone, cultivation_variety: :poaceae},
    common_wheat_crops:       { support_variety: :cultivable_zone, cultivation_variety: :triticum_aestivum},
    durum_wheat_crops:        { support_variety: :cultivable_zone, cultivation_variety: :triticum_durum},
    rye_crops:                { support_variety: :cultivable_zone, cultivation_variety: :secale},
    barley_crops:             { support_variety: :cultivable_zone, cultivation_variety: :hordeum},
    bere_crops:               { support_variety: :cultivable_zone, cultivation_variety: :hordeum_vulgare_hexastichum},
    oat_crops:                { support_variety: :cultivable_zone, cultivation_variety: :avena},
    maize_crops:              { support_variety: :cultivable_zone, cultivation_variety: :zea},
    triticale_crops:          { support_variety: :cultivable_zone, cultivation_variety: :triticosecale},
    rice_crops:               { support_variety: :cultivable_zone, cultivation_variety: :oryza},
    canary_grass_crops:       { support_variety: :cultivable_zone, cultivation_variety: :phalaris},
    sorghum_crops:            { support_variety: :cultivable_zone, cultivation_variety: :sorghum},
    cotton_crops:             { support_variety: :cultivable_zone, cultivation_variety: :gossypium},
    flax_crops:               { support_variety: :cultivable_zone, cultivation_variety: :linum},
    peanut_crops:             { support_variety: :cultivable_zone, cultivation_variety: :arachis},
    rapeseed_crops:           { support_variety: :cultivable_zone, cultivation_variety: :brassica_napus},
    sunflower_crops:          { support_variety: :cultivable_zone, cultivation_variety: :helianthus},
    soybean_crops:            { support_variety: :cultivable_zone, cultivation_variety: :glycine_max},
    theobroma_crops:          { support_variety: :cultivable_zone, cultivation_variety: :theobroma},
    cocoa_crops:              { support_variety: :cultivable_zone, cultivation_variety: :theobroma_cacao},
    leguminous_crops:         { support_variety: :cultivable_zone, cultivation_variety: :fabaceae},
    vetch_crops:              { support_variety: :cultivable_zone, cultivation_variety: :vicia},
    horsebean_crops:          { support_variety: :cultivable_zone, cultivation_variety: :vicia_faba},
    lupin_crops:              { support_variety: :cultivable_zone, cultivation_variety: :lupinus},
    pea_crops:                { support_variety: :cultivable_zone, cultivation_variety: :pisum},
    lentil_crops:             { support_variety: :cultivable_zone, cultivation_variety: :lens},
    chickpea_crops:           { support_variety: :cultivable_zone, cultivation_variety: :cicer},
    asparagus_crops:          { support_variety: :cultivable_zone, cultivation_variety: :asparagus},
    garlic_crops:             { support_variety: :cultivable_zone, cultivation_variety: :allium},
    carrot_crops:             { support_variety: :cultivable_zone, cultivation_variety: :daucus_carota},
    celery_crops:             { support_variety: :cultivable_zone, cultivation_variety: :apium_graveolens},
    cichorium_crops:          { support_variety: :cultivable_zone, cultivation_variety: :cichorium},
    cabbage_crops:            { support_variety: :cultivable_zone, cultivation_variety: :brassica_oleracea},
    flower_crops:             { support_variety: :cultivable_zone, cultivation_variety: :plant},
    bean_crops:               { support_variety: :cultivable_zone, cultivation_variety: :phaseolus},
    hop_crops:                { support_variety: :cultivable_zone, cultivation_variety: :humulus_lupulus},
    black_mustard_crops:      { support_variety: :cultivable_zone, cultivation_variety: :brassica_nigra},
    turnip_crops:             { support_variety: :cultivable_zone, cultivation_variety: :brassica_rapa},
    onion_crops:              { support_variety: :cultivable_zone, cultivation_variety: :allium_cepa},
    garden_pea_crops:         { support_variety: :cultivable_zone, cultivation_variety: :pisum_sativum},
    parsley_crops:            { support_variety: :cultivable_zone, cultivation_variety: :petroselinum},
    leek_crops:               { support_variety: :cultivable_zone, cultivation_variety: :allium_porrum},
    lettuce_crops:            { support_variety: :cultivable_zone, cultivation_variety: :lactuca},
    tobacco_crops:            { support_variety: :cultivable_zone, cultivation_variety: :nicotiana_tabacum},
    tomato_crops:             { support_variety: :cultivable_zone, cultivation_variety: :solanum_lycopersicum},
    citrus_orchards:          { support_variety: :cultivable_zone, cultivation_variety: :citrus},
    almond_orchards:          { support_variety: :cultivable_zone, cultivation_variety: :prunus_dulcis},
    carob_orchards:           { support_variety: :cultivable_zone, cultivation_variety: :ceratonia},
    chestnut_orchards:        { support_variety: :cultivable_zone, cultivation_variety: :castanea},
    hazel_orchards:           { support_variety: :cultivable_zone, cultivation_variety: :corylus},
    walnut_orchards:          { support_variety: :cultivable_zone, cultivation_variety: :juglans},
    olive_orchards:           { support_variety: :cultivable_zone, cultivation_variety: :olea},
    peach_orchards:           { support_variety: :cultivable_zone, cultivation_variety: :prunus_persica},
    pear_orchards:            { support_variety: :cultivable_zone, cultivation_variety: :pyrus},
    apple_orchards:           { support_variety: :cultivable_zone, cultivation_variety: :malus},
    plum_orchards:            { support_variety: :cultivable_zone, cultivation_variety: :prunus_domestica},
    pistachio_orchards:       { support_variety: :cultivable_zone, cultivation_variety: :pistacia},
    redcurrant_crops:         { support_variety: :cultivable_zone, cultivation_variety: :ribes_rubrum},
    blackcurrant_crops:       { support_variety: :cultivable_zone, cultivation_variety: :ribes_nigrum},
    raspberry_crops:          { support_variety: :cultivable_zone, cultivation_variety: :rubus_idaeus},
    strawberry_crops:         { support_variety: :cultivable_zone, cultivation_variety: :fragaria},
    muskmelon_crops:          { support_variety: :cultivable_zone, cultivation_variety: :cucumis_melo},
    pineapple_crops:          { support_variety: :cultivable_zone, cultivation_variety: :ananas},
    watermelon_crops:         { support_variety: :cultivable_zone, cultivation_variety: :citrullus_lanatus},
    lavender_crops:           { support_variety: :cultivable_zone, cultivation_variety: :lavandula},
    saffron_crops:            { support_variety: :cultivable_zone, cultivation_variety: :crocus_sativus},
    cattle_farming:   { support_variety: :animal_group, cultivation_variety: :bos},
    bison_farming:    { support_variety: :animal_group, cultivation_variety: :bison},
    sheep_farming:    { support_variety: :animal_group, cultivation_variety: :ovis},
    goat_farming:     { support_variety: :animal_group, cultivation_variety: :capra},
    pig_farming:      { support_variety: :animal_group, cultivation_variety: :suidae},
    oyster_farming:   { support_variety: :animal_group, cultivation_variety: :ostreidae},
    mussel_farming:   { support_variety: :animal_group, cultivation_variety: :mytilidae},
    scallop_farming:  { support_variety: :animal_group, cultivation_variety: :pectinidae},
    snail_farming:    { support_variety: :animal_group, cultivation_variety: :helicidae},
    beekeeping:       { support_variety: :animal_group, cultivation_variety: :apidae},
    poultry_farming:  { support_variety: :animal_group, cultivation_variety: :phasianidae},
    ostrich_farming:  { support_variety: :animal_group, cultivation_variety: :struthionidae},
    palmiped_farming: { support_variety: :animal_group, cultivation_variety: :anatidae},
    rabbit_farming:   { support_variety: :animal_group, cultivation_variety: :leporidae},
    salmon_farming:   { support_variety: :animal_group, cultivation_variety: :salmonidae},
    sturgeon_farming: { support_variety: :animal_group, cultivation_variety: :acipenseridae},
    wine: {}
  }

  def change
    execute "UPDATE journals SET closed_on = '1899-12-31' WHERE closed_on IS NULL"
    change_column_null :journals, :closed_on, false
    execute "UPDATE product_natures SET abilities_list = REPLACE(abilities_list, 'mollusca', 'gastropoda')"

    # Update activities
    execute "UPDATE activities SET family = 'maize_crops'  WHERE family LIKE 'corn_crops'"
    execute "UPDATE activities SET family = 'cereal_crops' WHERE family LIKE 'straw_cereal_%'"
    execute "UPDATE activities SET family = 'exploitation' WHERE family IS NULL OR family NOT IN (" + FAMILIES.map{|k,v| "'#{k}'"}.join(', ') + ")"
    families = FAMILIES.select{|k,v| v[:support_variety]}
    execute "UPDATE activities SET with_supports = family IN (" + families.map{|k,v| "'#{k}'"}.join(', ') +"), support_variety = CASE " + families.map{|k,v| "WHEN family = '#{k}' THEN '#{v[:support_variety]}'"}.join(' ') + " ELSE NULL END"
    families = FAMILIES.select{|k,v| v[:cultivation_variety]}
    execute "UPDATE activities SET with_cultivation = family IN (" + families.map{|k,v| "'#{k}'"}.join(', ') +"), cultivation_variety = CASE " + families.map{|k,v| "WHEN family = '#{k}' THEN '#{v[:cultivation_variety]}'"}.join(' ') + " ELSE NULL END"
    change_column_null :activities, :family, false

    # Update productions
    execute "UPDATE productions SET support_variant_id = pnv.id FROM product_nature_variants AS pnv, activities AS a WHERE support_variant_id IS NULL AND productions.activity_id = a.id AND a.support_variety IS NOT NULL AND pnv.variety = a.support_variety"
    execute "UPDATE productions SET cultivation_variant_id = pnv.id FROM product_nature_variants AS pnv, activities AS a WHERE cultivation_variant_id IS NULL AND productions.activity_id = a.id AND a.cultivation_variety IS NOT NULL AND pnv.variety = a.cultivation_variety"

    execute "UPDATE productions SET support_variant_indicator = 'net_surface_area', support_variant_unit = 'hectare' FROM activities AS a WHERE LENGTH(TRIM(support_variant_indicator)) <= 0 AND a.id = productions.activity_id AND a.support_variety = 'cultivable_zone'"
    execute "UPDATE productions SET support_variant_indicator = 'members_count', support_variant_unit = NULL FROM activities AS a WHERE LENGTH(TRIM(support_variant_indicator)) <= 0 AND a.id = productions.activity_id AND a.support_variety = 'animal_group'"
    execute "UPDATE productions SET support_variant_indicator = 'population', support_variant_unit = NULL FROM activities AS a WHERE LENGTH(TRIM(support_variant_indicator)) <= 0 AND a.id = productions.activity_id AND a.support_variety NOT IN ('cultivable_zone', 'animal_group')"

    add_column :production_supports, :quantity, :decimal, precision: 19, scale: 4
    add_column :production_supports, :quantity_indicator, :string
    add_column :production_supports, :quantity_unit, :string

    # FIXME Model code is prohibited in migrations
    Production.find_each do |p|
      # Select best activity
      if !p.with_supports and p.supports.any?
        puts p.supports.map(&:storage).map(&:variety).inspect.green
        p.support_variant = p.supports.first.storage.variant
        execute "UPDATE interventions SET production_support_id = NULL WHERE production_id = #{p.id}"
        p.supports.destroy_all
      end
      # Update supports
      if p.with_supports
        unless p.support_variant and Nomen::Varieties.find(p.support_variant.variety) <= p.support_variety
          support_variety = Nomen::Varieties.find(p.support_variety)
          item = Nomen::ProductNatureVariants.list.detect do |i|
            variety = i.variety || Nomen::ProductNatures.find(i.nature).variety
            support_variety >= variety
          end
          if item
            p.support_variant = ProductNatureVariant.import_from_nomenclature(item.name)
          else
            raise "What #{support_variety}"
          end
        end
        quantifiers = p.support_variant.quantifiers
        if p.support_variant_indicator.blank? or !quantifiers.include?("#{p.support_variant_indicator}/#{p.support_variant_unit}")
          quantifier = quantifiers.last.split('/')
          p.support_variant_indicator = quantifier.first
          p.support_variant_unit = quantifier.second
        end
        p.supports.each do |support|
          value = support.storage.get(p.support_variant_indicator, at: p.started_at)
          value = value.convert(p.support_variant_unit) if p.support_variant_unit
          execute("UPDATE production_supports SET quantity_indicator = '#{p.support_variant_indicator}', quantity_unit = '#{p.support_variant_unit}', quantity = #{value.to_f} WHERE id = #{support.id}")
        end
      end
      # Set cultivation
      if p.with_cultivation
        unless p.cultivation_variant and Nomen::Varieties.find(p.cultivation_variant.variety) <= p.cultivation_variety
          cultivation_variety = Nomen::Varieties.find(p.cultivation_variety)
          item = Nomen::ProductNatureVariants.list.detect do |i|
            variety = i.variety || Nomen::ProductNatures.find(i.nature).variety
            cultivation_variety >= variety
          end
          if item
            p.cultivation_variant = ProductNatureVariant.import_from_nomenclature(item.name)
          else
            raise "What #{cultivation_variety}"
          end
        end
      end
      p.save!
    end

    change_column_null :production_supports, :quantity, false
    change_column_null :production_supports, :quantity_indicator, false
  end
end
