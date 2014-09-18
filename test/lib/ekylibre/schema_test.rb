# encoding: UTF-8
require 'test_helper'

class Ekylibre::SchemaTest < ActiveSupport::TestCase

  # Checks the validity of references files for models
  def test_ekylibre_tables
    for k, v in Ekylibre::Schema.tables
      for n, column in v
        unless column.references.nil?
          assert(column.references.present?, "#{k}.#{n} foreign key is not determined.")
          unless column.polymorphic?
            assert_nothing_raised do
              column.references.to_s.pluralize.classify.constantize
            end
          end
        end
      end
    end
  end

end
