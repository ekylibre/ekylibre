# encoding: UTF-8
require 'test_helper'

class Ekylibre::SchemaTest < ActiveSupport::TestCase
  # Checks the validity of references files for models
  test 'ekylibre tables' do
    for k, v in Ekylibre::Schema.tables
      for n, column in v
        next if column.references.nil?
        assert(column.references.present?, "#{k}.#{n} foreign key is not determined.")
        next if column.polymorphic?
        assert_nothing_raised do
          column.references.to_s.pluralize.classify.constantize
        end
      end
    end
  end

  test 'uniqueness of model human names' do
    names = Ekylibre::Schema.models.collect do |model|
      model.to_s.classify.constantize.model_name.human
    end
    assert_equal names.size, names.uniq.size, 'Not unique names in models: ' + names.uniq.select { |t| names.count { |l| l == t } > 1 }.sort.to_sentence(locale: :eng)
  end
end
