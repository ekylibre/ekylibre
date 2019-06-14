require 'test_helper'

class FixturesTest < Ekylibre::Testing::ApplicationTestCase::WithFixtures
  # Checks the validity of references files for models

  Ekylibre::Schema.models.sort.each do |model_name|
    model = model_name.to_s.classify.constantize

    test "all fixtures validity: #{model.name}" do
      invalids = []
      # print "#{model.name.green}"
      reflections = model.reflect_on_all_associations(:belongs_to).delete_if { |r| r.name.to_s == 'item' && model == Version }
      model.includes(reflections.collect(&:name)).each do |record|
        begin
          unless record.valid?
            invalids << "#{model.name}##{record.id}: #{record.errors.full_messages.to_sentence}"
          end
        rescue ActiveRecord::RecordInvalid => e
          invalids << "#{model.name}##{record.id}: #{e.class.name} raised: #{e.message}"
        end
        reflections.each do |reflection|
          id = record.send(reflection.foreign_key)
          if id && id.to_i > 0 && record.send(reflection.name).blank?
            invalids << "#{model.name}##{record.id}: Invalid #{reflection.foreign_key} value: #{record.send(reflection.foreign_key)} (#{reflection.class_name})"
          end
        end
      end
      assert invalids.empty?, "#{invalids.count} records are invalid: \n" + invalids.join("\n").dig(2)
    end
  end
end
