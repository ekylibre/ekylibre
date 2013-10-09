module ActiveList

  module Definition
    autoload :Table,             'active-list/definition/table'
    autoload :AbstractColumn,    'active-list/definition/abstract_column'
    autoload :EmptyColumn,       'active-list/definition/empty_column'
    autoload :DataColumn,        'active-list/definition/data_column'
    autoload :AttributeColumn,   'active-list/definition/attribute_column'
    autoload :AssociationColumn, 'active-list/definition/association_column'
    autoload :ActionColumn,      'active-list/definition/action_column'
    autoload :FieldColumn,       'active-list/definition/field_column'
    autoload :TextFieldColumn,   'active-list/definition/text_field_column'
    autoload :CheckBoxColumn,    'active-list/definition/check_box_column'
  end

end
