# frozen_string_literal: true

# = Informations
#
# == License
#
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2009 Brice Texier, Thibaud Merigon
# Copyright (C) 2010-2012 Brice Texier
# Copyright (C) 2012-2014 Brice Texier, David Joulin
# Copyright (C) 2015-2023 Ekylibre SAS
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
# == Table: analytic_segments
#
#  analytic_sequence_id :integer(4)       not null
#  created_at           :datetime         not null
#  id                   :integer(4)       not null, primary key
#  name                 :string           not null
#  position             :integer(4)       not null
#  updated_at           :datetime         not null
#

class AnalyticSegment < ApplicationRecord
  belongs_to :analytic_sequence

  enumerize :name, in: %i[activities project_budgets teams equipments]

  before_create do
    last_segment = analytic_sequence.segments.last
    self.position = 0 unless analytic_sequence.segments.any?
    self.position = last_segment.position + 1 if analytic_sequence.segments.any?
  end
end
