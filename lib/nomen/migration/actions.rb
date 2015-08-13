module Nomen
  module Migration
    module Actions
      autoload :ItemChange,           'nomen/migration/actions/item_change'
      autoload :ItemCreation,         'nomen/migration/actions/item_creation'
      autoload :ItemMerging,          'nomen/migration/actions/item_merging'
      autoload :NomenclatureCreation, 'nomen/migration/actions/nomenclature_creation'
      autoload :PropertyCreation,     'nomen/migration/actions/property_creation'
    end
  end
end
