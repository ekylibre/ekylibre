# = Informations
#
# == License
#
# Ekylibre - Simple ERP
# Copyright (C) 2009-2013 Brice Texier, Thibaud Merigon
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see http://www.gnu.org/licenses.
#
# == Table: product_memberships
#
#  created_at   :datetime         not null
#  creator_id   :integer
#  group_id     :integer          not null
#  id           :integer          not null, primary key
#  lock_version :integer          default(0), not null
#  member_id    :integer          not null
#  operation_id :integer
#  started_at   :datetime         not null
#  stopped_at   :datetime
#  updated_at   :datetime         not null
#  updater_id   :integer
#


class ProductMembership < Ekylibre::Record::Base
  include Taskable
  belongs_to :group, class_name: "ProductGroup"
  belongs_to :member, class_name: "Product"
  #[VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_presence_of :group, :member, :started_at
  #]VALIDATORS]

  scope :at, lambda { |at| where("? BETWEEN COALESCE(started_at, ?) AND COALESCE(stopped_at, ?)", at, at, at) }

  validate do
    # TODO Checks that no time overlaps can occur and that it works
    #errors.add(:started_at, :invalid) unless self.similars.where("stopped_at IS NULL AND (started_at IS NOT NULL OR started_at <=?)", self.started_at).count.zero?
  end

  def similars
    self.class.where(:group_id => self.group_id, :member_id => self.member_id)
  end

end
