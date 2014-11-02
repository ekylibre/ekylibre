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
# == Table: guides
#
#  active                        :boolean          not null
#  created_at                    :datetime         not null
#  creator_id                    :integer
#  external                      :boolean          not null
#  frequency                     :string(255)      not null
#  id                            :integer          not null, primary key
#  lock_version                  :integer          default(0), not null
#  name                          :string(255)      not null
#  nature                        :string(255)      not null
#  reference_name                :string(255)
#  reference_source_content_type :string(255)
#  reference_source_file_name    :string(255)
#  reference_source_file_size    :integer
#  reference_source_updated_at   :datetime
#  updated_at                    :datetime         not null
#  updater_id                    :integer
#

class Guide < Ekylibre::Record::Base
  has_many :analyses, class_name: "GuideAnalysis"
  has_one :last_analysis, -> { where(latest: true) }, class_name: "GuideAnalysis"
  enumerize :nature, in: Nomen::GuideNatures.all
  enumerize :frequency, in: [:hourly, :daily, :weekly, :monthly, :yearly, :decadely, :none], default: :none
  enumerize :reference_name, in: []

  has_attached_file :reference_source, path: ':tenant/:class/:id/source.xml'

  #[VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_datetime :reference_source_updated_at, allow_nil: true, on_or_after: Date.civil(1,1,1)
  validates_numericality_of :reference_source_file_size, allow_nil: true, only_integer: true
  validates_length_of :frequency, :name, :nature, :reference_name, :reference_source_content_type, :reference_source_file_name, allow_nil: true, maximum: 255
  validates_inclusion_of :active, :external, in: [true, false]
  validates_presence_of :frequency, :name, :nature
  #]VALIDATORS]
  validates_inclusion_of :nature, in: self.nature.values
  validates_inclusion_of :frequency, in: self.frequency.values
  validates_attachment_content_type :reference_source, content_type: /xml/

  delegate :status, to: :last_analysis, prefix: true

  def status
    self.last_analysis ? self.last_analysis_status : :undefined
  end

  def run!(started_at = Time.now)
    statuses = [:passed, :passed_with_warnings, :failed]
    global_status = statuses.sample
    analysis = self.analyses.create!(acceptance_status: global_status, started_at: started_at, stopped_at: started_at + 10)
    (4 * self.name.size).times do |i|
      status = statuses[0..(statuses.index(global_status))].sample
      analysis.points.create!(acceptance_status: status, reference_name: "#{self.name.parameterize.underscore}_check_#{i}", advice_reference_name: (status.to_s == "failed" ? "do_something" : nil))
    end
  end

end
