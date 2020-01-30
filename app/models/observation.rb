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
# == Table: observations
#
#  author_id    :integer          not null
#  content      :text             not null
#  created_at   :datetime         not null
#  creator_id   :integer
#  id           :integer          not null, primary key
#  importance   :string           not null
#  lock_version :integer          default(0), not null
#  observed_at  :datetime         not null
#  subject_id   :integer          not null
#  subject_type :string           not null
#  updated_at   :datetime         not null
#  updater_id   :integer
#

class Observation < Ekylibre::Record::Base
  enumerize :importance, in: %i[important normal notice], default: :notice, predicates: true
  belongs_to :subject, polymorphic: true
  belongs_to :author, class_name: 'User'
  # [VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates :content, presence: true, length: { maximum: 500_000 }
  validates :author, :importance, :subject, presence: true
  validates :observed_at, presence: true, timeliness: { on_or_after: -> { Time.new(1, 1, 1).in_time_zone }, on_or_before: -> { Time.zone.now + 50.years } }
  validates :subject_type, presence: true, length: { maximum: 500 }
  # ]VALIDATORS]
  validates :importance, length: { allow_nil: true, maximum: 10 }

  before_validation do
    self.subject_type = subject.class.base_class.name if subject
    self.importance ||= self.class.importance.default_value
    self.observed_at ||= Time.zone.now
    begin
      self.author_id ||= self.class.stamper_class.stamper
    rescue
      nil
    end
  end

  validate do
    if self.observed_at && self.observed_at > Time.zone.now
      errors.add(:observed_at, :invalid)
    end
  end

  def subject_type=(class_name)
    unless normalized_class_name = begin
                                     class_name.to_s.classify.constantize.base_class.name
                                   rescue
                                     nil
                                   end
      raise "Invalid class name: #{class_name.inspect}"
    end
    super(normalized_class_name)
  end
end
