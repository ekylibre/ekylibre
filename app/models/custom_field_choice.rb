# = Informations
#
# == License
#
# Ekylibre ERP - Simple agricultural ERP
# Copyright (C) 2008-2009 Brice Texier, Thibaud Merigon
# Copyright (C) 2010-2012 Brice Texier
# Copyright (C) 2012-2015 Brice Texier, David Joulin
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
#  name            :string(255)      not null
#  position        :integer
#  updated_at      :datetime         not null
#  updater_id      :integer
#  value           :string(255)
#


class CustomFieldChoice < Ekylibre::Record::Base
  # attr_accessible :name, :custom_field_id, :position
  belongs_to :custom_field, inverse_of: :choices
  acts_as_list :scope => :custom_field
  #[VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_length_of :name, :value, allow_nil: true, maximum: 255
  validates_presence_of :custom_field, :name
  #]VALIDATORS]
  validates_presence_of :value
  validates_uniqueness_of :value, :name, :scope => :custom_field_id

  before_validation do
    self.value ||= self.name.to_s.codeize # if self.value.blank?
    self.value = self.value.mb_chars.downcase.gsub(/[[:space:]\_]+/, '-').gsub(/(^\-+|\-+$)/, '')[0..62]
    if self.custom_field
      while self.custom_field.choices.where(:value => self.value).where("id != ?", self.id || 0).count > 0
        self.value.succ!
      end
    end
  end

  before_update do
    old = self.old_record
    if self.value != old.value and self.custom_field.column_exists?
      self.custom_field.customized_model.where(self.custom_field.column_name => old.value).update_all(self.custom_field.column_name => self.value)
    end
  end

  # Check that no records are present with this choice
  protect(on: :destroy) do
    return self.records.any?
  end

  # Returns.all linked records for the given model
  def records
    return self.custom_field.customized_model.where(self.custom_field.column_name => self.value)
  end

end
