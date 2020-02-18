# = Informations
#
# == License
#
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2009 Brice Texier, Thibaud Merigon
# Copyright (C) 2010-2012 Brice Texier
# Copyright (C) 2012-2014 Brice Texier, David Joulin
# Copyright (C) 2015-2020 Ekylibre SAS
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see http://www.gnu.org/licenses.
#
# == Table: custom_fields
#
#  active          :boolean          default(TRUE), not null
#  column_name     :string           not null
#  created_at      :datetime         not null
#  creator_id      :integer
#  customized_type :string           not null
#  id              :integer          not null, primary key
#  lock_version    :integer          default(0), not null
#  maximal_length  :integer
#  maximal_value   :decimal(19, 4)
#  minimal_length  :integer
#  minimal_value   :decimal(19, 4)
#  name            :string           not null
#  nature          :string           not null
#  position        :integer
#  required        :boolean          default(FALSE), not null
#  updated_at      :datetime         not null
#  updater_id      :integer
#

require 'test_helper'

class CustomFieldTest < Ekylibre::Testing::ApplicationTestCase::WithFixtures
  test_model_actions
  STATIC_VALUES = {
    text: 'Lorem ipsum',
    decimal: 3.14159,
    boolean: true,
    date: '1953-03-16', # Date.civil(1953, 3, 16),
    datetime: Time.new(1953, 3, 16, 12, 23)
  }.stringify_keys.freeze

  Ekylibre::Schema.models.each do |model_name|
    model = model_name.to_s.camelcase.constantize
    if !model.respond_to?(:customizable?) || !model.customizable?
      test "should not add custom fields on #{model_name}" do
        assert_raise ActiveRecord::RecordInvalid, "Souldn't add custom field on not customizable models like #{model.name}" do
          CustomField.create!(name: 'たてがみ', nature: :text, customized_type: model.name)
        end
      end
    else
      test "should manipulate custom fields on #{model_name}" do
        I18n.locale = ENV['LOCALE'] || I18n.default_locale
        CustomField.nature.values.each do |nature|
          field = CustomField.create!(
            name: "#{nature.capitalize} info",
            nature: nature,
            customized_type: model.name
          )
          first_column_name = field.column_name
          field.name = "#{nature.capitalize} インフォ"
          field.save!
          assert_equal first_column_name, field.column_name, 'Column name should not change'

          record = model.all.detect { |r| r.valid? && r.updateable? }
          assert record.present?, "A valid and updateable #{model.name} must exist to test custom fields on it"

          # Set value
          method_name = "#{field.column_name}="
          record.custom_fields ||= {}
          if STATIC_VALUES.key?(field.nature)
            record.custom_fields[field.column_name] = STATIC_VALUES[field.nature]
          elsif field.choice?
            3.times do |index|
              field.choices.create!(name: "Marvelous ##{index}")
            end
            choice = field.choices.sample
            record.custom_fields[field.column_name] = choice.value
          else
            raise "Unknown custom field datatype: #{field.nature.inspect}"
          end

          record.save!
          record.reload
          assert record.custom_fields.is_a?(Hash), 'Custom fields should be a Hash'
          value = record.custom_fields[field.column_name]
          assert value.present?, "A value must be present in custom field #{field.column_name.inspect} after update. Got: #{value.inspect} from #{record.custom_fields.inspect}:#{record.custom_fields.class.name}"

          if STATIC_VALUES.key?(field.nature)
            assert_equal STATIC_VALUES[field.nature], value, "Recorded value in custom field #{field.column_name} differs from expected"
          elsif field.choice?
            assert_equal choice.value, value, "Selected choice in custom field #{field.column_name} differs from expected"
          else
            raise "Unknown custom field datatype: #{field.nature.inspect}"
          end

          field.destroy!
        end
      end
    end
  end
end
