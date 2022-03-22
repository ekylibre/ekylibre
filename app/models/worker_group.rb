# frozen_string_literal: true

# = Informations
#
# == License
#
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2009 Brice Texier, Thibaud Merigon
# Copyright (C) 2010-2012 Brice Texier
# Copyright (C) 2012-2014 Brice Texier, David Joulin
# Copyright (C) 2015-2021 Ekylibre SAS
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
# == Table: worker_group
#
#  activity_production_id       :integer
#  address_id                   :integer
#  birth_date_completeness      :string
#  birth_farm_number            :string
#  born_at                      :datetime
#  category_id                  :integer          not null
#  codes                        :jsonb
class WorkerGroup < ApplicationRecord
  has_many :items, class_name: "WorkerGroupItem", dependent: :destroy
  has_many :labellings, class_name: 'WorkerGroupLabelling', dependent: :destroy
  has_many :labels, through: :labellings
  has_many :workers, through: :items, source: :worker, source_type: 'Product'
  accepts_nested_attributes_for :items, allow_destroy: true
  accepts_nested_attributes_for :labellings, allow_destroy: true, reject_if: :label_already_present

  # [VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates :name, presence: true, length: { maximum: 500 }

  scope :at, ->(at) { where(arel_table[:created_at].lteq(at)) }

  def group_size
    items.size
  end

  def workers_name
    Worker.find(items.map(&:worker_id)).map(&:name).join(", ")
  end

  def label_names
    labellings.collect(&:name).sort.join(', ')
  end

  private

    def label_already_present(attributes)
      labellings.reject(&:marked_for_destruction?).map(&:label_id).include?(attributes[:label_id].to_i)
    end

end
