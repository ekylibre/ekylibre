class ChangeProductionReferenceInActivities < ActiveRecord::Migration[5.0]

  ID_REFERENCES = {
    '1' => 'winter_oat', '2' => 'spring_oat', '3' => 'winter_hard_wheat', '4' => 'spring_hard_wheat', '5' => 'winter_common_wheat',
    '6' => 'spring_common_wheat', '7' => 'spelt', '8' => 'sweet_corn', '9' => 'silage_corn', '10' => 'grain_corn', '11' => 'winter_barley',
    '12' => 'spring_barley', '13' => 'rice', '14' => 'buckwheat', '15' => 'winter_rye', '16' => 'spring_rye', '17' => 'sorghum',
    '18' => 'winter_triticale', '19' => 'spring_triticale', '20' => 'winter_rape', '21' => 'spring_rape', '22' => 'soy', '23' => 'sunflower',
    '24' => 'winter_field_bean', '25' => 'spring_field_bean', '26' => 'winter_sweet_lupin', '27' => 'spring_sweet_lupin', '28' => 'dehydrated_alfalfa',
    '29' => 'dehydrated_melilot', '30' => 'winter_proteaginous_pea', '31' => 'spring_proteaginous_pea', '32' => 'dehydrated_sainfoin',
    '33' => 'dehydrated_clover', '34' => 'hemp', '35' => 'fiber_flax', '36' => 'fresh_lentil', '37' => 'chickpea', '38' => 'alfalfa', '39' => 'melilot',
    '40' => 'clover', '41' => 'fodder_beetroot', '42' => 'fodder_carrot', '43' => 'fodder_cabbage', '44' => 'spring_fodder_field_bean',
    '45' => 'winter_fodder_field_bean', '46' => 'fodder_lentil', '47' => 'winter_fodder_lupin', '48' => 'spring_fodder_lupin', '49' => 'fodder_turnip',
    '50' => 'winter_fodder_pea', '51' => 'spring_fodder_pea', '52' => 'fodder_radish', '53' => 'garlic', '54' => 'garlic', '55' => 'artichoke',
    '56' => 'eggplant', '57' => 'beetroot', '58' => 'chard', '59' => 'carrot', '60' => 'celery', '61' => 'witloof', '62' => 'curly_endive',
    '63' => 'cauliflower', '64' => 'broccoli', '65' => 'white_cabbage', '66' => 'cucumber', '67' => 'pickle', '68' => 'squash',
    '69' => 'butternut_squash', '70' => 'zucchini', '71' => 'pumpkin', '72' => 'spring_spinach', '73' => 'winter_spinach', '74' => 'broad_bean',
    '75' => 'strawberry', '76' => 'dried_bean', '77' => 'hop', '78' => 'lettuce', '79' => 'batavia', '80' => 'oakleaf', '81' => 'cornsalad',
    '82' => 'melon', '83' => 'early_turnip', '84' => 'winter_turnip', '85' => 'onion', '86' => 'shallot', '87' => 'parsnip', '88' => 'watermelon',
    '89' => 'pea', '90' => 'leek', '91' => 'pepper', '92' => 'chili', '93' => 'potato', '94' => 'potato', '95' => 'sugar_pumpkin', '96' => 'red_kuri',
    '97' => 'radish', '98' => 'rocket', '99' => 'rutabaga', '100' => 'salsify', '101' => 'tobacco', '102' => 'tomato', '103' => 'jerusalem_artichoke',
    '104' => 'dill', '105' => 'anise', '106' => 'basil', '107' => 'chamomile', '108' => 'chive', '109' => 'coriander', '110' => 'tarragon',
    '111' => 'fennel', '112' => 'apricot', '113' => 'asparagus', '114' => 'burdock', '115' => 'sugar_cane', '116' => 'blackcurrant', '117' => 'cherry',
    '118' => 'chesnut', '119' => 'oak', '120' => 'lemon', '121' => 'quince', '122' => 'cotton', '123' => 'meadow', '124' => 'cocksfoot',
    '125' => 'eucalyptus', '126' => 'fig', '127' => 'raspberry', '129' => 'redcurrant', '130' => 'fallow', '131' => 'cherry_laurel', '132' => 'lavender',
    '133' => 'birds_foot_trefoil', '134' => 'birds_foot_trefoil', '135' => 'cassava', '136' => 'miscanthus', '137' => 'mustard', '138' => 'hazelnut',
    '139' => 'walnut', '140' => 'olive', '141' => 'orange', '142' => 'grapefruit', '143' => 'sweet_patato', '144' => 'peach', '146' => 'pear',
    '147' => 'apple', '148' => 'meadow', '149' => 'plum', '150' => 'quinoa', '151' => 'ryegrass', '153' => 'common_vetch', '154' => 'vine',
    '155' => 'garlic', '156' => 'pineapple', '157' => 'angelica', '158' => 'peanut', '159' => 'winter_avena_cereal', '160' => 'winter_hordeum_cereal',
    '161' => 'winter_secale_cereal', '162' => 'winter_triticum_cereal', '163' => 'cereal', '164' => 'fagopoyrum_cereal', '165' => 'panicum_cereal',
    '166' => 'phalaris_cereal', '167' => 'setaria_cereal', '168' => 'sorghum_cereal', '169' => 'spring_avena_cereal', '170' => 'spring_hordeum_cereal',
    '171' => 'spring_secale_cereal', '172' => 'spring_triticum_cereal', '173' => 'spring_zea_cereal', '175' => 'winter_fodder_field_bean',
    '175' => 'spring_fodder_field_bean', '176' => 'fodder_specie', '177' => 'meadow', '178' => 'tufted_vetch', '179' => 'annual_fruit',
    '179' => 'annual_vegetable', '180' => 'orchard', '180' => 'perennial_vegetable', '181' => 'winter_fodder_lupin', '182' => 'spring_fodder_lupin',
    '183' => 'alfalfa', '184' => 'leguminous_mix', '185' => 'melilot', '186' => 'helianthus_oleaginous', '187' => 'winter_brassica_napus_oleaginous',
    '188' => 'winter_brassica_rapa_oleaginous', '189' => 'oleaginous', '190' => 'spring_brassica_napus_oleaginous',
    '191' => 'spring_brassica_rapa_oleaginous', '192' => 'fodder_specie', '193' => 'winter_fodder_pea', '194' => 'spring_fodder_pea',
    '195' => 'annual_ornamental_plant_and_mapp', '196' => 'perrenial_ornamental_plant_and_mapp', '197' => 'meadow', '198' => 'proteaginous',
    '199' => 'sainfoin', '200' => 'birds_foot', '201' => 'clover', '202' => 'common_vetch', '203' => 'avocado', '204' => 'banana', '205' => 'banana',
    '206' => 'banana', '207' => 'banana', '208' => 'banana', '209' => 'banana', '210' => 'banana', '211' => 'banana', '212' => 'banana',
    '213' => 'banana', '214' => 'border', '215' => 'border', '216' => 'border', '217' => 'cornflower', '218' => 'meadow', '219' => 'border',
    '220' => 'borage', '221' => 'bromus', '222' => 'bugle', '223' => 'cocoa', '224' => 'coffee', '225' => 'camelina', '226' => 'sugar_cane',
    '227' => 'sugar_cane', '228' => 'sugar_cane', '229' => 'sugar_cane', '230' => 'carob', '231' => 'caraway', '232' => 'chervil', '233' => 'cherry',
    '234' => 'marian_thistle', '235' => 'chesnut', '236' => 'oak', '237' => 'black_eyed_pea', '238' => 'cress', '239' => 'cress', '242' => 'interrow',
    '243' => 'interrow', '244' => 'cumin', '245' => 'turmeric', '246' => 'catjang', '247' => 'fenugreek', '248' => 'fescue', '249' => 'timothy',
    '250' => 'fodder_species_mix', '251' => 'galium', '252' => 'geranium', '253' => 'withe_pea', '254' => 'annual_ornamental_plant_and_mapp',
    '255' => 'annual_ornamental_plant_and_mapp', '257' => 'fallow', '258' => 'fallow', '259' => 'fallow', '260' => 'tufted_vetch',
    '261' => 'dehydrated_tufted_vetch', '262' => 'annual_vegetable', '263' => 'winter_flax', '264' => 'spring_flax', '265' => 'birds_foot_trefoil',
    '266' => 'birds_foot_trefoil', '268' => 'oxeye_daisy', '269' => 'marjoram', '270' => 'mallow', '271' => 'oleaginous_mix', '272' => 'cereal_mix',
    '273' => 'leguminous_mix', '274' => 'meadow', '275' => 'leguminous_mix', '276' => 'fodder_species_mix', '277' => 'proteaginous_mix',
    '278' => 'fodder_species_mix', '279' => 'lemon_balm', '280' => 'mint', '281' => 'st_johns_wort', '282' => 'millet', '283' => 'black_medick',
    '284' => 'black_medick', '285' => 'black_medick', '286' => 'foxtail_millet', '287' => 'summer_field_mustard', '288' => 'winter_field_mustard',
    '289' => 'nyger', '290' => 'opium_poppy', '291' => 'nettle', '292' => 'sorrel', '293' => 'common_daisy', '294' => 'rough_bluegrass',
    '295' => 'peach', '296' => 'pansy', '297' => 'nursery', '298' => 'parsley', '299' => 'phacelia', '300' => 'pistachio', '301' => 'blond_psyllium',
    '302' => 'annual_ornamental_plant_and_mapp', '303' => 'annual_ornamental_plant_and_mapp', '304' => 'annual_ornamental_plant_and_mapp',
    '305' => 'pear', '306' => 'meadow', '307' => 'primrose', '308' => 'plum', '309' => 'black_psyllium', '310' => 'vine', '311' => 'rosemary',
    '312' => 'meadow', '313' => 'sainfoin', '314' => 'savory', '315' => 'sage', '316' => 'birds_foot', '317' => 'dehydrated_birds_foot',
    '320' => 'meadow', '321' => 'meadow', '323' => 'thyme', '324' => 'tomato', '326' => 'annual_vegetable', '327' => 'valerian', '328' => 'vanilla',
    '329' => 'vanilla', '330' => 'vanilla', '331' => 'orchard', '332' => 'speedwell', '333' => 'dehydrated_common_vetch', '334' => 'vetiver',
    '335' => 'vine', '336' => 'vine', '337' => 'festulolium', '338' => 'ylang_ylang', '339' => 'fallow', '340' => 'meadow',
    '341' => 'birds_foot_trefoil', '342' => 'black_medick', '343' => 'celeriac', '344' => 'escarole', '345' => 'watercress', '346' => 'green_bean',
    '347' => 'dried_lentil', '348' => 'dried_pea', '349' => 'giant_granadilla', '350' => 'hemp', '351' => 'napa_cabbage', '352' => 'brussels_sprout',
    '353' => 'kohlrabi', '354' => 'guava', '355' => 'yam', '356' => 'persimmon', '357' => 'kiwi', '358' => 'longan', '359' => 'mandarin',
    '360' => 'mulberry', '361' => 'blackberry', '362' => 'purslane', '363' => 'castor_bean', '364' => 'black_elderberry'
  }.freeze

  def change
    add_column :activities, :reference_name, :string

    request = ID_REFERENCES.map do |id, reference_name|
      <<-SQL
        UPDATE activities
          SET reference_name = '#{reference_name}'
        WHERE production_nature_id = #{id}
      SQL
    end

    execute request.join(';')

    remove_column :activities, :production_nature_id
  end
end
