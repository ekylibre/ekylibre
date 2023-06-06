# frozen_string_literal: true

# = Informations
#
# == License
#
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2009 Brice Texier, Thibaud Merigon
# Copyright (C) 2010-2012 Brice Texier
# Copyright (C) 2012-2018 Brice Texier, David Joulin
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
# == Table: issue_natures
#
#  category :string           not null
#  id       :integer          not null, primary key
#  label    :string           not null
#  nature   :string           not null
#

class IssueNature < ApplicationRecord
  refers_to :nature, class_name: 'IssueNature'

  has_many :issues, class_name: 'Issue', inverse_of: :issue_nature

  scope :of_category, lambda { |category|
    where(category: category)
  }

  class << self
    def categories
      pluck(:category).uniq
    end

    def all_label_values
      all.collect { |i| [i.label, i.id, data: { category: i.category }] }
    end

    def labels_of_category(category)
      of_category(category).collect { |i| [i.label, i.id] }
    end
  end
end
