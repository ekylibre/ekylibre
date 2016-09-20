# coding: utf-8
class AddBookkeepAttributesToStockTables < ActiveRecord::Migration
  # Built with following code:
  # Nomen::ProductNatureCategory.list.each_with_object({}) { |c, h| next if c.stock_movement_account.blank?; a = Nomen::Account.find(c.stock_movement_account); h[c.name.to_sym] = { name: I18n.available_locales.each_with_object({}) {|l,h| h[l] = a.human_name(locale: l) }, usages: a.name, number: a.fr_pcga || a.fr_pcg82 } }.to_yaml
  STOCK_MOVEMENT_ACCOUNTS = YAML.load <<-YAML
---
:animal_food:
  :name:
    :arb: Livestock feed stocks variation
    :cmn: Livestock feed stocks variation
    :deu: Livestock feed stocks variation
    :eng: Livestock feed stocks variation
    :fra: Variation de stock d’aliment du bétail
    :ita: Livestock feed stocks variation
    :jpn: Livestock feed stocks variation
    :por: Livestock feed stocks variation
    :spa: Livestock feed stocks variation
  :usages: livestock_feed_stocks_variation
  :number: '60314'
:animal_medicine:
  :name:
    :arb: Animal medicine stocks variation
    :cmn: Animal medicine stocks variation
    :deu: Animal medicine stocks variation
    :eng: Animal medicine stocks variation
    :fra: Variations de stock de produits de défense des animaux
    :ita: Animal medicine stocks variation
    :jpn: Animal medicine stocks variation
    :por: Animal medicine stocks variation
    :spa: Animal medicine stocks variation
  :usages: animal_medicine_stocks_variation
  :number: '60315'
:animal_reproduction:
  :name:
    :arb: Animal reproduction stocks variation
    :cmn: Animal reproduction stocks variation
    :deu: Animal reproduction stocks variation
    :eng: Animal reproduction stocks variation
    :fra: Variation de stock de produits de reproduction animale
    :ita: Animal reproduction stocks variation
    :jpn: Animal reproduction stocks variation
    :por: Animal reproduction stocks variation
    :spa: Animal reproduction stocks variation
  :usages: animal_reproduction_stocks_variation
  :number: '60316'
:aves_band:
  :name:
    :arb: "الحيوانات دورة قصيرة تغيرات المخزون"
    :cmn: "周期短的动物库存变化"
    :deu: Kurze Zyklus Tiere Inventar Variationen
    :eng: Short cycle animals inventory variations
    :fra: Variations d’inventaires ‒ animaux (cycle court)
    :ita: animali ciclo brevi variazioni di inventario
    :jpn: "短いサイクル動物在庫変動"
    :por: Animais de ciclo curto variações de inventário
    :spa: Animales de ciclo corto variaciones de inventario
  :usages: short_cycle_animals_inventory_variations
  :number: '7132'
:bee_band:
  :name:
    :arb: "الحيوانات دورة طويلة تغيرات المخزون"
    :cmn: "周期长动物库存变化"
    :deu: Lange Zyklus Tiere Inventar Variationen
    :eng: Long cycle animals inventory variations
    :fra: Variations d’inventaires ‒ animaux (cycle long)
    :ita: animali lungo ciclo variazioni di inventario
    :jpn: "ロングサイクル動物在庫変動"
    :por: Animais de ciclo longo variações de inventário
    :spa: Animales largo ciclo variaciones de inventario
  :usages: long_cycle_animals_inventory_variations
  :number: '7131'
:biological_auxiliary:
  :name:
    :arb: Plant medicine stocks variation
    :cmn: Plant medicine stocks variation
    :deu: Plant medicine stocks variation
    :eng: Plant medicine stocks variation
    :fra: Variations de stock de produits de défense des végétaux
    :ita: Plant medicine stocks variation
    :jpn: Plant medicine stocks variation
    :por: Plant medicine stocks variation
    :spa: Plant medicine stocks variation
  :usages: plant_medicine_stocks_variation
  :number: '60313'
:calf:
  :name:
    :arb: "الحيوانات دورة قصيرة تغيرات المخزون"
    :cmn: "周期短的动物库存变化"
    :deu: Kurze Zyklus Tiere Inventar Variationen
    :eng: Short cycle animals inventory variations
    :fra: Variations d’inventaires ‒ animaux (cycle court)
    :ita: animali ciclo brevi variazioni di inventario
    :jpn: "短いサイクル動物在庫変動"
    :por: Animais de ciclo curto variações de inventário
    :spa: Animales de ciclo corto variaciones de inventario
  :usages: short_cycle_animals_inventory_variations
  :number: '7132'
:construction_materials_in_own_outstanding_installation:
  :name:
    :arb: Merchandising stocks variation
    :cmn: Merchandising stocks variation
    :deu: Merchandising stocks variation
    :eng: Merchandising stocks variation
    :fra: Variations de stock de marchandises
    :ita: Merchandising stocks variation
    :jpn: Merchandising stocks variation
    :por: Merchandising stocks variation
    :spa: Merchandising stocks variation
  :usages: merchandising_stocks_variation
  :number: '6037'
:crop:
  :name:
    :arb: "دورة قصيرة vegetals تغيرات المخزون"
    :cmn: "周期短vegetals库存变化"
    :deu: Kurze Zyklus Vegetals Inventar Variationen
    :eng: Short cycle vegetals inventory variations
    :fra: Variations d’inventaires ‒ végétaux (cycle court)
    :ita: Ciclo Corto Vegetali variazioni di inventario
    :jpn: "ショートサイクルvegetals在庫変動"
    :por: Ciclo curto Vegetais variações de inventário
    :spa: Ciclo corto VEGETALS variaciones de inventario
  :usages: short_cycle_vegetals_inventory_variations
  :number: '7134'
:egg:
  :name:
    :arb: "منتجات تغيرات المخزون"
    :cmn: "产品库存变化"
    :deu: Produkte Inventar Variationen
    :eng: Products inventory variations
    :fra: Variations d’inventaires ‒ produits
    :ita: Prodotti variazioni di inventario
    :jpn: "製品の在庫変動"
    :por: Produtos variações de inventário
    :spa: Productos variaciones de inventario
  :usages: products_inventory_variations
  :number: '7137'
:female_adult_cow:
  :name:
    :arb: "الحيوانات دورة طويلة تغيرات المخزون"
    :cmn: "周期长动物库存变化"
    :deu: Lange Zyklus Tiere Inventar Variationen
    :eng: Long cycle animals inventory variations
    :fra: Variations d’inventaires ‒ animaux (cycle long)
    :ita: animali lungo ciclo variazioni di inventario
    :jpn: "ロングサイクル動物在庫変動"
    :por: Animais de ciclo longo variações de inventário
    :spa: Animales largo ciclo variaciones de inventario
  :usages: long_cycle_animals_inventory_variations
  :number: '7131'
:female_adult_pig:
  :name:
    :arb: "الحيوانات دورة طويلة تغيرات المخزون"
    :cmn: "周期长动物库存变化"
    :deu: Lange Zyklus Tiere Inventar Variationen
    :eng: Long cycle animals inventory variations
    :fra: Variations d’inventaires ‒ animaux (cycle long)
    :ita: animali lungo ciclo variazioni di inventario
    :jpn: "ロングサイクル動物在庫変動"
    :por: Animais de ciclo longo variações de inventário
    :spa: Animales largo ciclo variaciones de inventario
  :usages: long_cycle_animals_inventory_variations
  :number: '7131'
:female_young_cow:
  :name:
    :arb: "الحيوانات دورة طويلة تغيرات المخزون"
    :cmn: "周期长动物库存变化"
    :deu: Lange Zyklus Tiere Inventar Variationen
    :eng: Long cycle animals inventory variations
    :fra: Variations d’inventaires ‒ animaux (cycle long)
    :ita: animali lungo ciclo variazioni di inventario
    :jpn: "ロングサイクル動物在庫変動"
    :por: Animais de ciclo longo variações de inventário
    :spa: Animales largo ciclo variaciones de inventario
  :usages: long_cycle_animals_inventory_variations
  :number: '7131'
:fertilizer:
  :name:
    :arb: Fertilizer stocks variation
    :cmn: Fertilizer stocks variation
    :deu: Fertilizer stocks variation
    :eng: Fertilizer stocks variation
    :fra: Variations de stock d’engrais et amendements
    :ita: Fertilizer stocks variation
    :jpn: Fertilizer stocks variation
    :por: Fertilizer stocks variation
    :spa: Fertilizer stocks variation
  :usages: fertilizer_stocks_variation
  :number: '60311'
:fish_band:
  :name:
    :arb: "الحيوانات دورة قصيرة تغيرات المخزون"
    :cmn: "周期短的动物库存变化"
    :deu: Kurze Zyklus Tiere Inventar Variationen
    :eng: Short cycle animals inventory variations
    :fra: Variations d’inventaires ‒ animaux (cycle court)
    :ita: animali ciclo brevi variazioni di inventario
    :jpn: "短いサイクル動物在庫変動"
    :por: Animais de ciclo curto variações de inventário
    :spa: Animales de ciclo corto variaciones de inventario
  :usages: short_cycle_animals_inventory_variations
  :number: '7132'
:fruit:
  :name:
    :arb: "منتجات تغيرات المخزون"
    :cmn: "产品库存变化"
    :deu: Produkte Inventar Variationen
    :eng: Products inventory variations
    :fra: Variations d’inventaires ‒ produits
    :ita: Prodotti variazioni di inventario
    :jpn: "製品の在庫変動"
    :por: Produtos variações de inventário
    :spa: Productos variaciones de inventario
  :usages: products_inventory_variations
  :number: '7137'
:fuel:
  :name:
    :arb: "تباين الأسهم إمدادات أخرى"
    :cmn: "其他股票供给变化"
    :deu: Andere Versorgungs Aktien Variation
    :eng: Other supply stocks variation
    :fra: Variation des stocks autres approvisionnements
    :ita: Altri stock di approvvigionamento variazione
    :jpn: "その他の供給株式変動"
    :por: Variação outras ações de abastecimento
    :spa: Variación de otras poblaciones de suministro
  :usages: other_supply_stocks_variation
  :number: '6032'
:gas:
  :name:
    :arb: "تباين الأسهم إمدادات أخرى"
    :cmn: "其他股票供给变化"
    :deu: Andere Versorgungs Aktien Variation
    :eng: Other supply stocks variation
    :fra: Variation des stocks autres approvisionnements
    :ita: Altri stock di approvvigionamento variazione
    :jpn: "その他の供給株式変動"
    :por: Variação outras ações de abastecimento
    :spa: Variación de otras poblaciones de suministro
  :usages: other_supply_stocks_variation
  :number: '6032'
:grain:
  :name:
    :arb: "منتجات تغيرات المخزون"
    :cmn: "产品库存变化"
    :deu: Produkte Inventar Variationen
    :eng: Products inventory variations
    :fra: Variations d’inventaires ‒ produits
    :ita: Prodotti variazioni di inventario
    :jpn: "製品の在庫変動"
    :por: Produtos variações de inventário
    :spa: Productos variaciones de inventario
  :usages: products_inventory_variations
  :number: '7137'
:grass:
  :name:
    :arb: "منتجات تغيرات المخزون"
    :cmn: "产品库存变化"
    :deu: Produkte Inventar Variationen
    :eng: Products inventory variations
    :fra: Variations d’inventaires ‒ produits
    :ita: Prodotti variazioni di inventario
    :jpn: "製品の在庫変動"
    :por: Produtos variações de inventário
    :spa: Productos variaciones de inventario
  :usages: products_inventory_variations
  :number: '7137'
:honey:
  :name:
    :arb: "منتجات تغيرات المخزون"
    :cmn: "产品库存变化"
    :deu: Produkte Inventar Variationen
    :eng: Products inventory variations
    :fra: Variations d’inventaires ‒ produits
    :ita: Prodotti variazioni di inventario
    :jpn: "製品の在庫変動"
    :por: Produtos variações de inventário
    :spa: Productos variaciones de inventario
  :usages: products_inventory_variations
  :number: '7137'
:long_time_animal:
  :name:
    :arb: "الحيوانات دورة طويلة تغيرات المخزون"
    :cmn: "周期长动物库存变化"
    :deu: Lange Zyklus Tiere Inventar Variationen
    :eng: Long cycle animals inventory variations
    :fra: Variations d’inventaires ‒ animaux (cycle long)
    :ita: animali lungo ciclo variazioni di inventario
    :jpn: "ロングサイクル動物在庫変動"
    :por: Animais de ciclo longo variações de inventário
    :spa: Animales largo ciclo variaciones de inventario
  :usages: long_cycle_animals_inventory_variations
  :number: '7131'
:male_adult_cow:
  :name:
    :arb: "الحيوانات دورة طويلة تغيرات المخزون"
    :cmn: "周期长动物库存变化"
    :deu: Lange Zyklus Tiere Inventar Variationen
    :eng: Long cycle animals inventory variations
    :fra: Variations d’inventaires ‒ animaux (cycle long)
    :ita: animali lungo ciclo variazioni di inventario
    :jpn: "ロングサイクル動物在庫変動"
    :por: Animais de ciclo longo variações de inventário
    :spa: Animales largo ciclo variaciones de inventario
  :usages: long_cycle_animals_inventory_variations
  :number: '7131'
:male_adult_pig:
  :name:
    :arb: "الحيوانات دورة طويلة تغيرات المخزون"
    :cmn: "周期长动物库存变化"
    :deu: Lange Zyklus Tiere Inventar Variationen
    :eng: Long cycle animals inventory variations
    :fra: Variations d’inventaires ‒ animaux (cycle long)
    :ita: animali lungo ciclo variazioni di inventario
    :jpn: "ロングサイクル動物在庫変動"
    :por: Animais de ciclo longo variações de inventário
    :spa: Animales largo ciclo variaciones de inventario
  :usages: long_cycle_animals_inventory_variations
  :number: '7131'
:male_young_cow:
  :name:
    :arb: "الحيوانات دورة طويلة تغيرات المخزون"
    :cmn: "周期长动物库存变化"
    :deu: Lange Zyklus Tiere Inventar Variationen
    :eng: Long cycle animals inventory variations
    :fra: Variations d’inventaires ‒ animaux (cycle long)
    :ita: animali lungo ciclo variazioni di inventario
    :jpn: "ロングサイクル動物在庫変動"
    :por: Animais de ciclo longo variações de inventário
    :spa: Animales largo ciclo variaciones de inventario
  :usages: long_cycle_animals_inventory_variations
  :number: '7131'
:meat:
  :name:
    :arb: "منتجات تغيرات المخزون"
    :cmn: "产品库存变化"
    :deu: Produkte Inventar Variationen
    :eng: Products inventory variations
    :fra: Variations d’inventaires ‒ produits
    :ita: Prodotti variazioni di inventario
    :jpn: "製品の在庫変動"
    :por: Produtos variações de inventário
    :spa: Productos variaciones de inventario
  :usages: products_inventory_variations
  :number: '7137'
:milk:
  :name:
    :arb: "منتجات تغيرات المخزون"
    :cmn: "产品库存变化"
    :deu: Produkte Inventar Variationen
    :eng: Products inventory variations
    :fra: Variations d’inventaires ‒ produits
    :ita: Prodotti variazioni di inventario
    :jpn: "製品の在庫変動"
    :por: Produtos variações de inventário
    :spa: Productos variaciones de inventario
  :usages: products_inventory_variations
  :number: '7137'
:oenological_product:
  :name:
    :arb: Plant medicine stocks variation
    :cmn: Plant medicine stocks variation
    :deu: Plant medicine stocks variation
    :eng: Plant medicine stocks variation
    :fra: Variations de stock de produits de défense des végétaux
    :ita: Plant medicine stocks variation
    :jpn: Plant medicine stocks variation
    :por: Plant medicine stocks variation
    :spa: Plant medicine stocks variation
  :usages: plant_medicine_stocks_variation
  :number: '60313'
:office_furniture_equipment:
  :name:
    :arb: "تباين الأسهم إمدادات أخرى"
    :cmn: "其他股票供给变化"
    :deu: Andere Versorgungs Aktien Variation
    :eng: Other supply stocks variation
    :fra: Variation des stocks autres approvisionnements
    :ita: Altri stock di approvvigionamento variazione
    :jpn: "その他の供給株式変動"
    :por: Variação outras ações de abastecimento
    :spa: Variación de otras poblaciones de suministro
  :usages: other_supply_stocks_variation
  :number: '6032'
:other_consumable:
  :name:
    :arb: "تباين الأسهم إمدادات أخرى"
    :cmn: "其他股票供给变化"
    :deu: Andere Versorgungs Aktien Variation
    :eng: Other supply stocks variation
    :fra: Variation des stocks autres approvisionnements
    :ita: Altri stock di approvvigionamento variazione
    :jpn: "その他の供給株式変動"
    :por: Variação outras ações de abastecimento
    :spa: Variación de otras poblaciones de suministro
  :usages: other_supply_stocks_variation
  :number: '6032'
:oyster_band:
  :name:
    :arb: "الحيوانات دورة قصيرة تغيرات المخزون"
    :cmn: "周期短的动物库存变化"
    :deu: Kurze Zyklus Tiere Inventar Variationen
    :eng: Short cycle animals inventory variations
    :fra: Variations d’inventaires ‒ animaux (cycle court)
    :ita: animali ciclo brevi variazioni di inventario
    :jpn: "短いサイクル動物在庫変動"
    :por: Animais de ciclo curto variações de inventário
    :spa: Animales de ciclo corto variaciones de inventario
  :usages: short_cycle_animals_inventory_variations
  :number: '7132'
:package_consumable:
  :name:
    :arb: "تباين الأسهم إمدادات أخرى"
    :cmn: "其他股票供给变化"
    :deu: Andere Versorgungs Aktien Variation
    :eng: Other supply stocks variation
    :fra: Variation des stocks autres approvisionnements
    :ita: Altri stock di approvvigionamento variazione
    :jpn: "その他の供給株式変動"
    :por: Variação outras ações de abastecimento
    :spa: Variación de otras poblaciones de suministro
  :usages: other_supply_stocks_variation
  :number: '6032'
:pig_band:
  :name:
    :arb: "الحيوانات دورة قصيرة تغيرات المخزون"
    :cmn: "周期短的动物库存变化"
    :deu: Kurze Zyklus Tiere Inventar Variationen
    :eng: Short cycle animals inventory variations
    :fra: Variations d’inventaires ‒ animaux (cycle court)
    :ita: animali ciclo brevi variazioni di inventario
    :jpn: "短いサイクル動物在庫変動"
    :por: Animais de ciclo curto variações de inventário
    :spa: Animales de ciclo corto variaciones de inventario
  :usages: short_cycle_animals_inventory_variations
  :number: '7132'
:plant:
  :name:
    :arb: "دورة طويلة vegetals تغيرات المخزون"
    :cmn: "周期长vegetals库存变化"
    :deu: Lange Zyklus Vegetals Inventar Variationen
    :eng: Long cycle vegetals inventory variations
    :fra: Variations d’inventaires ‒ végétaux (cycle long)
    :ita: lungo ciclo Vegetali variazioni di inventario
    :jpn: "ロングサイクルvegetals在庫変動"
    :por: Longo ciclo de Vegetais variações de inventário
    :spa: Ciclo largo VEGETALS variaciones de inventario
  :usages: long_cycle_vegetals_inventory_variations
  :number: '7133'
:plant_medicine:
  :name:
    :arb: Plant medicine stocks variation
    :cmn: Plant medicine stocks variation
    :deu: Plant medicine stocks variation
    :eng: Plant medicine stocks variation
    :fra: Variations de stock de produits de défense des végétaux
    :ita: Plant medicine stocks variation
    :jpn: Plant medicine stocks variation
    :por: Plant medicine stocks variation
    :spa: Plant medicine stocks variation
  :usages: plant_medicine_stocks_variation
  :number: '60313'
:processed_grain:
  :name:
    :arb: Merchandising stocks variation
    :cmn: Merchandising stocks variation
    :deu: Merchandising stocks variation
    :eng: Merchandising stocks variation
    :fra: Variations de stock de marchandises
    :ita: Merchandising stocks variation
    :jpn: Merchandising stocks variation
    :por: Merchandising stocks variation
    :spa: Merchandising stocks variation
  :usages: merchandising_stocks_variation
  :number: '6037'
:processed_meat:
  :name:
    :arb: Merchandising stocks variation
    :cmn: Merchandising stocks variation
    :deu: Merchandising stocks variation
    :eng: Merchandising stocks variation
    :fra: Variations de stock de marchandises
    :ita: Merchandising stocks variation
    :jpn: Merchandising stocks variation
    :por: Merchandising stocks variation
    :spa: Merchandising stocks variation
  :usages: merchandising_stocks_variation
  :number: '6037'
:processed_milk:
  :name:
    :arb: Merchandising stocks variation
    :cmn: Merchandising stocks variation
    :deu: Merchandising stocks variation
    :eng: Merchandising stocks variation
    :fra: Variations de stock de marchandises
    :ita: Merchandising stocks variation
    :jpn: Merchandising stocks variation
    :por: Merchandising stocks variation
    :spa: Merchandising stocks variation
  :usages: merchandising_stocks_variation
  :number: '6037'
:rabbit_band:
  :name:
    :arb: "الحيوانات دورة قصيرة تغيرات المخزون"
    :cmn: "周期短的动物库存变化"
    :deu: Kurze Zyklus Tiere Inventar Variationen
    :eng: Short cycle animals inventory variations
    :fra: Variations d’inventaires ‒ animaux (cycle court)
    :ita: animali ciclo brevi variazioni di inventario
    :jpn: "短いサイクル動物在庫変動"
    :por: Animais de ciclo curto variações de inventário
    :spa: Animales de ciclo corto variaciones de inventario
  :usages: short_cycle_animals_inventory_variations
  :number: '7132'
:raw_materials:
  :name:
    :arb: "تباين الأسهم إمدادات أخرى"
    :cmn: "其他股票供给变化"
    :deu: Andere Versorgungs Aktien Variation
    :eng: Other supply stocks variation
    :fra: Variation des stocks autres approvisionnements
    :ita: Altri stock di approvvigionamento variazione
    :jpn: "その他の供給株式変動"
    :por: Variação outras ações de abastecimento
    :spa: Variación de otras poblaciones de suministro
  :usages: other_supply_stocks_variation
  :number: '6032'
:seed:
  :name:
    :arb: Seed stocks variation
    :cmn: Seed stocks variation
    :deu: Seed stocks variation
    :eng: Seed stocks variation
    :fra: Variations de stock de semences et plants
    :ita: Seed stocks variation
    :jpn: Seed stocks variation
    :por: Seed stocks variation
    :spa: Seed stocks variation
  :usages: seed_stocks_variation
  :number: '60312'
:short_time_animal:
  :name:
    :arb: "الحيوانات دورة قصيرة تغيرات المخزون"
    :cmn: "周期短的动物库存变化"
    :deu: Kurze Zyklus Tiere Inventar Variationen
    :eng: Short cycle animals inventory variations
    :fra: Variations d’inventaires ‒ animaux (cycle court)
    :ita: animali ciclo brevi variazioni di inventario
    :jpn: "短いサイクル動物在庫変動"
    :por: Animais de ciclo curto variações de inventário
    :spa: Animales de ciclo corto variaciones de inventario
  :usages: short_cycle_animals_inventory_variations
  :number: '7132'
:small_electronic_equipment:
  :name:
    :arb: "تباين الأسهم إمدادات أخرى"
    :cmn: "其他股票供给变化"
    :deu: Andere Versorgungs Aktien Variation
    :eng: Other supply stocks variation
    :fra: Variation des stocks autres approvisionnements
    :ita: Altri stock di approvvigionamento variazione
    :jpn: "その他の供給株式変動"
    :por: Variação outras ações de abastecimento
    :spa: Variación de otras poblaciones de suministro
  :usages: other_supply_stocks_variation
  :number: '6032'
:small_equipment:
  :name:
    :arb: "تباين الأسهم إمدادات أخرى"
    :cmn: "其他股票供给变化"
    :deu: Andere Versorgungs Aktien Variation
    :eng: Other supply stocks variation
    :fra: Variation des stocks autres approvisionnements
    :ita: Altri stock di approvvigionamento variazione
    :jpn: "その他の供給株式変動"
    :por: Variação outras ações de abastecimento
    :spa: Variación de otras poblaciones de suministro
  :usages: other_supply_stocks_variation
  :number: '6032'
:straw:
  :name:
    :arb: "منتجات تغيرات المخزون"
    :cmn: "产品库存变化"
    :deu: Produkte Inventar Variationen
    :eng: Products inventory variations
    :fra: Variations d’inventaires ‒ produits
    :ita: Prodotti variazioni di inventario
    :jpn: "製品の在庫変動"
    :por: Produtos variações de inventário
    :spa: Productos variaciones de inventario
  :usages: products_inventory_variations
  :number: '7137'
:vegetable:
  :name:
    :arb: "منتجات تغيرات المخزون"
    :cmn: "产品库存变化"
    :deu: Produkte Inventar Variationen
    :eng: Products inventory variations
    :fra: Variations d’inventaires ‒ produits
    :ita: Prodotti variazioni di inventario
    :jpn: "製品の在庫変動"
    :por: Produtos variações de inventário
    :spa: Productos variaciones de inventario
  :usages: products_inventory_variations
  :number: '7137'
:wine:
  :name:
    :arb: "منتجات تغيرات المخزون"
    :cmn: "产品库存变化"
    :deu: Produkte Inventar Variationen
    :eng: Products inventory variations
    :fra: Variations d’inventaires ‒ produits
    :ita: Prodotti variazioni di inventario
    :jpn: "製品の在庫変動"
    :por: Produtos variações de inventário
    :spa: Productos variaciones de inventario
  :usages: products_inventory_variations
  :number: '7137'
:wine_package_consumable:
  :name:
    :arb: "تباين الأسهم إمدادات أخرى"
    :cmn: "其他股票供给变化"
    :deu: Andere Versorgungs Aktien Variation
    :eng: Other supply stocks variation
    :fra: Variation des stocks autres approvisionnements
    :ita: Altri stock di approvvigionamento variazione
    :jpn: "その他の供給株式変動"
    :por: Variação outras ações de abastecimento
    :spa: Variación de otras poblaciones de suministro
  :usages: other_supply_stocks_variation
  :number: '6032'
YAML

  def change
    # Adds stock movement account
    add_reference :product_nature_categories, :stock_movement_account, index: true

    # Create missing accounts and configure existing product nature categories with
    # last version of nomenclature
    reversible do |d|
      d.up do
        locale = select_value("SELECT string_value FROM preferences WHERE name = 'language'")
        locale = locale.blank? ? :eng : locale.to_sym

        # Adds missing accounts
        query = 'INSERT INTO accounts (name, number, label, usages, created_at, updated_at) SELECT DISTINCT '
        query << 'CASE ' + STOCK_MOVEMENT_ACCOUNTS.map do |cat, account|
          "WHEN pnc.reference_name = '#{cat}' THEN '#{account[:name][locale]}'"
        end.join(' ') + ' END, '
        query << 'CASE ' + STOCK_MOVEMENT_ACCOUNTS.map do |cat, account|
          "WHEN pnc.reference_name = '#{cat}' THEN '#{account[:number]}'"
        end.join(' ') + ' END, '
        query << 'CASE ' + STOCK_MOVEMENT_ACCOUNTS.map do |cat, account|
          "WHEN pnc.reference_name = '#{cat}' THEN '#{account[:number]} – #{account[:name][locale]}'"
        end.join(' ') + ' END, '
        query << 'CASE ' + STOCK_MOVEMENT_ACCOUNTS.map do |cat, account|
          "WHEN pnc.reference_name = '#{cat}' THEN '#{account[:usages]}'"
        end.join(' ') + ' END, '
        query << 'CURRENT_TIMESTAMP, CURRENT_TIMESTAMP'
        query << '  FROM product_nature_categories AS pnc'
        query << '    LEFT JOIN accounts AS a ON (pnc.reference_name = CASE ' + STOCK_MOVEMENT_ACCOUNTS.map do |cat, account|
          "WHEN a.usages = '#{account[:usages]}' THEN '#{cat}'"
        end.join(' ') + ' END)'
        query << '  WHERE pnc.reference_name IN (' + STOCK_MOVEMENT_ACCOUNTS.keys.map do |k|
          "'#{k}'"
        end.join(', ') + ')'
        query << '    AND a.number IS NULL'
        execute query

        # Updates product_nature_categories with movement
        execute 'UPDATE product_nature_categories SET stock_movement_account_id = a.id FROM accounts AS a' \
                ' WHERE a.usages = CASE ' + STOCK_MOVEMENT_ACCOUNTS.map { |cat, account| "WHEN reference_name = '#{cat}' THEN '#{account[:usages]}'" }.join(' ') + ' END'
      end
    end

    # Product nature variant
    rename_column :product_nature_variants, :number, :work_number
    add_column :product_nature_variants, :number, :string, index: true
    add_reference :product_nature_variants, :stock_account, index: true
    add_reference :product_nature_variants, :stock_movement_account, index: true
    reversible do |d|
      d.up do
        # Fill number column
        execute 'UPDATE product_nature_variants SET number = LPAD(id::VARCHAR, 8, \'0\')'

        %w(stock stock_movement).each do |account|
          # Create missing stock accounts
          execute 'INSERT INTO accounts (name, number, label, usages, created_at, updated_at) ' \
                  '  SELECT sa.name || \' – \' || pnv.name, ' \
                  '    sa.number || pnv.number, sa.number || pnv.number || \' – \' || pnv.name, ' \
                  '    sa.usages, sa.created_at, sa.updated_at' \
                  '  FROM product_nature_variants AS pnv ' \
                  '    JOIN product_nature_categories AS pnc ON (pnv.category_id = pnc.id)' \
                  "    JOIN accounts AS sa ON (pnc.#{account}_account_id = sa.id)" \
                  '  WHERE sa.number IS NOT NULL'

          # Update stock account of variants
          execute 'UPDATE product_nature_variants AS pnv ' \
                  "  SET #{account}_account_id = sac.id " \
                  '  FROM product_nature_categories AS pnc ' \
                  "    JOIN accounts AS sa ON (pnc.#{account}_account_id = sa.id) " \
                  '    JOIN accounts AS sac ON (sa.usages = sac.usages AND sac.number LIKE sa.number || \'%\')' \
                  '  WHERE category_id = pnc.id AND sac.number = sa.number || pnv.number'
        end
      end
    end
    change_column_null :product_nature_variants, :number, false
    add_index :product_nature_variants, :number, unique: true

    # add currency, journal_entry and accounted_at to parcels
    add_column :parcels, :accounted_at, :datetime
    add_column :parcels, :currency, :string
    add_reference :parcels, :journal_entry, index: true
    add_column :parcel_items, :currency, :string
    add_column :parcel_items, :unit_pretax_stock_amount, :decimal, precision: 19, scale: 4, default: 0.0, null: false

    # add currency, journal_entry and accounted_at to interventions
    add_column :interventions, :accounted_at, :datetime
    add_column :interventions, :currency, :string
    add_reference :interventions, :journal_entry, index: true
    add_column :intervention_parameters, :currency, :string
    add_column :intervention_parameters, :unit_pretax_stock_amount, :decimal, precision: 19, scale: 4, default: 0.0, null: false

    # add currency to inventories
    add_reference :inventories, :financial_year, index: true
    add_column :inventories, :currency, :string
    add_column :inventory_items, :currency, :string
    add_column :inventory_items, :unit_pretax_stock_amount, :decimal, precision: 19, scale: 4, default: 0.0, null: false
  end
end
