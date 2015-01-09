# = Informations
#
# == License
#
# Ekylibre - Simple agricultural ERP
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
# == Table: observations
#
#  author_id    :integer          not null
#  content      :text             not null
#  created_at   :datetime         not null
#  creator_id   :integer
#  id           :integer          not null, primary key
#  importance   :string(10)       not null
#  lock_version :integer          default(0), not null
#  observed_at  :datetime         not null
#  subject_id   :integer          not null
#  subject_type :string(255)      not null
#  updated_at   :datetime         not null
#  updater_id   :integer
#


class Observation < Ekylibre::Record::Base
  enumerize :importance, in: [:important, :normal, :notice], default: :notice, predicates: true
  belongs_to :subject, polymorphic: true
  belongs_to :author, class_name: "User"
  #[VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_datetime :observed_at, allow_blank: true, on_or_after: Time.new(1, 1, 1, 0, 0, 0, '+00:00')
  validates_length_of :importance, allow_nil: true, maximum: 10
  validates_length_of :subject_type, allow_nil: true, maximum: 255
  validates_presence_of :author, :content, :importance, :observed_at, :subject, :subject_type
  #]VALIDATORS]

  before_validation do
    if self.subject
      self.subject_type = self.subject.class.name
    end
    self.importance ||= self.class.importance.default_value
    self.observed_at ||= Time.now
    self.author_id ||= self.class.stamper_class.stamper rescue nil
  end

  def subject_type=(class_name)
    unless normalized_class_name = class_name.to_s.classify.constantize.base_class.name rescue nil
      raise "Invalid class name: #{class_name.inspect}"
    end
    super(normalized_class_name)
  end

end
