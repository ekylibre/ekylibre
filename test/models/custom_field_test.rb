# -*- coding: utf-8 -*-
# = Informations
#
# == License
#
# Ekylibre ERP - Simple agricultural ERP
# Copyright (C) 2008-2009 Brice Texier, Thibaud Merigon
# Copyright (C) 2010-2012 Brice Texier
# Copyright (C) 2012-2014 Brice Texier, David Joulin
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
#  column_name     :string(255)      not null
#  created_at      :datetime         not null
#  creator_id      :integer
#  customized_type :string(255)      not null
#  id              :integer          not null, primary key
#  lock_version    :integer          default(0), not null
#  maximal_length  :integer
#  maximal_value   :decimal(19, 4)
#  minimal_length  :integer
#  minimal_value   :decimal(19, 4)
#  name            :string(255)      not null
#  nature          :string(20)       not null
#  position        :integer
#  required        :boolean          not null
#  updated_at      :datetime         not null
#  updater_id      :integer
#


require 'test_helper'

class CustomFieldTest < ActiveSupport::TestCase

  for model in Ekylibre::Record::Base.descendants
    test "manage custom field on #{model.name.underscore}" do
      if CustomField.customized_type.values.include?(model.name)
        assert_raise ActiveRecord::RecordInvalid, "Cannot add custom field on not customizable models like #{model.name}" do
          CustomField.create!(name: "たてがみ", nature: :text, customized_type: model.name)
        end
      else
        for nature in CustomField.nature.values
          field = CustomField.create!(name: "#{nature.capitalize} info", nature: nature, customized_type: model.name)
          assert model.connection.columns(model.table_name).detect{|c| c.name.to_s == field.column_name}

          field.name = "#{nature.capitalize} インフォ"
          field.save
          assert model.connection.columns(model.table_name).detect{|c| c.name.to_s == field.column_name}

          column_name = field.column_name
          field.destroy
          assert !model.connection.columns(model.table_name).detect{|c| c.name.to_s == column_name}
        end
      end
    end
  end

end
