require 'test_helper'

module Ekylibre
  class SchemaTest < Ekylibre::Testing::ApplicationTestCase::WithFixtures
    # Checks the validity of references files for models
    test 'ekylibre tables' do
      Ekylibre::Schema.tables.each do |table, columns|
        columns.each do |n, column|
          next if column.references.nil?

          puts table.inspect.red
          puts column.inspect.yellow

          assert(column.references.present?, "#{table}.#{n} foreign key is not determined.")
          next if column.polymorphic?

          assert_nothing_raised do
            column.references.to_s.pluralize.classify.constantize
          end
        end
      end
    end

    test 'uniqueness of model human names, except for sti models' do
      models = Ekylibre::Schema.models.reject do |model_name|
        model = model_name.to_s.classify.constantize
        model.respond_to?('sti_descendant?') && model.sti_descendant?
      end

      names = models.map do |model|
        model.to_s.classify.constantize.model_name.human
      end
      assert_equal names.size, names.uniq.size, 'Not unique names in models: ' + names.uniq.select { |t| names.count { |l| l == t } > 1 }.sort.to_sentence(locale: :eng)
    end
  end
end
