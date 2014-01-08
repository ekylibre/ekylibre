module ActiveList

  module Definition
    autoload :AbstractColumn,    'active_list/definition/abstract_column'
    autoload :ActionColumn,      'active_list/definition/action_column'
    autoload :AssociationColumn, 'active_list/definition/association_column'
    autoload :AttributeColumn,   'active_list/definition/attribute_column'
    autoload :CheckBoxColumn,    'active_list/definition/check_box_column'
    autoload :DataColumn,        'active_list/definition/data_column'
    autoload :EmptyColumn,       'active_list/definition/empty_column'
    autoload :FieldColumn,       'active_list/definition/field_column'
    autoload :StatusColumn,      'active_list/definition/status_column'
    autoload :Table,             'active_list/definition/table'
    autoload :TextFieldColumn,   'active_list/definition/text_field_column'
  end

end
