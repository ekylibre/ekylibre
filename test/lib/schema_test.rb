# encoding: UTF-8
require 'test_helper'

class SchemaTest < ActiveSupport::TestCase

  # Checks the validity of references files for models
  def test_ekylibre_tables
    for k, v in Ekylibre.tables
      for n, column in v
        if column.references != nil
          assert(column.references.blank?, "#{k}.#{n} foreign key is not determined.")
          unless column.polymorphic?
            assert_nothing_raised do
              column.references.pluralize.classify.constantize
            end
          end
        end
      end
    end
  end

end
