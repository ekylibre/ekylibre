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
# == Table: custom_field_choices
#
#  created_at      :datetime         not null
#  creator_id      :integer
#  custom_field_id :integer          not null
#  id              :integer          not null, primary key
#  lock_version    :integer          default(0), not null
#  name            :string           not null
#  position        :integer
#  updated_at      :datetime         not null
#  updater_id      :integer
#  value           :string
#

class CustomFieldChoice < Ekylibre::Record::Base
  belongs_to :custom_field, inverse_of: :choices
  acts_as_list scope: :custom_field
  # [VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates :name, presence: true, length: { maximum: 500 }
  validates :value, length: { maximum: 500 }, allow_blank: true
  validates :custom_field, presence: true
  # ]VALIDATORS]
  validates :value, presence: true
  validates :value, :name, uniqueness: { scope: :custom_field_id, case_sensitive: false }

  before_validation do
    self.value ||= name.to_s.codeize # if self.value.blank?
    self.value = self.value.mb_chars.gsub(/[[:space:]\_]+/, '-').gsub(/(^\-+|\-+$)/, '')[0..62]
    if custom_field
      while custom_field.choices.where(value: self.value).where('id != ?', id || 0).count > 0
        self.value.succ!
      end
    end
  end

  before_update do
    old = old_record
    if self.value != old.value
      custom_field.customized_model.where("custom_fields->>'#{custom_field.column_name}' = ?", old.value).update_all("custom_fields = jsonb_set(custom_fields, '{#{custom_field.column_name}}', to_jsonb(#{self.class.connection.quote(self.value)}::VARCHAR))")
    end
  end

  # Check that no records are present with this choice
  protect(on: :destroy) do
    return records.any?
  end

  # Returns all linked records for the given model
  def records
    custom_field.customized_model.where("custom_fields->>'#{custom_field.column_name}' = ?", self.value)
  end
end
