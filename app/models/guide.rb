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
# == Table: guides
#
#  active                        :boolean          default(FALSE), not null
#  created_at                    :datetime         not null
#  creator_id                    :integer
#  external                      :boolean          default(FALSE), not null
#  frequency                     :string           not null
#  id                            :integer          not null, primary key
#  lock_version                  :integer          default(0), not null
#  name                          :string           not null
#  nature                        :string           not null
#  reference_name                :string
#  reference_source_content_type :string
#  reference_source_file_name    :string
#  reference_source_file_size    :integer
#  reference_source_updated_at   :datetime
#  updated_at                    :datetime         not null
#  updater_id                    :integer
#

class Guide < Ekylibre::Record::Base
  has_many :analyses, class_name: 'GuideAnalysis', dependent: :destroy
  has_one :last_analysis, -> { where(latest: true) }, class_name: 'GuideAnalysis'
  refers_to :nature, class_name: 'GuideNature'
  enumerize :frequency, in: %i[hourly daily weekly monthly yearly decadely none], default: :none
  enumerize :reference_name, in: []

  has_attached_file :reference_source, path: ':tenant/:class/:id/source.xml'

  # [VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates :active, :external, inclusion: { in: [true, false] }
  validates :frequency, :nature, presence: true
  validates :name, presence: true, length: { maximum: 500 }
  validates :reference_source_content_type, :reference_source_file_name, length: { maximum: 500 }, allow_blank: true
  validates :reference_source_file_size, numericality: { only_integer: true, greater_than: -2_147_483_649, less_than: 2_147_483_648 }, allow_blank: true
  validates :reference_source_updated_at, timeliness: { on_or_after: -> { Time.new(1, 1, 1).in_time_zone }, on_or_before: -> { Time.zone.now + 50.years } }, allow_blank: true
  # ]VALIDATORS]
  validates :nature, inclusion: { in: nature.values }
  validates :frequency, inclusion: { in: frequency.values }
  validates_attachment_content_type :reference_source, content_type: /xml/

  delegate :status, to: :last_analysis, prefix: true

  def status
    last_analysis ? last_analysis_status : :undefined
  end

  def run!(started_at = Time.zone.now)
    statuses = %i[passed passed_with_warnings failed]
    global_status = statuses.sample
    analysis = analyses.create!(acceptance_status: global_status, started_at: started_at, stopped_at: started_at + 10)
    (4 * name.size).times do |i|
      status = statuses[0..(statuses.index(global_status))].sample
      analysis.points.create!(acceptance_status: status, reference_name: "#{name.parameterize.underscore}_check_#{i}", advice_reference_name: (status.to_s == 'failed' ? 'do_something' : nil))
    end
  end
end
