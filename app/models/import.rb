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
# == Table: imports
#
#  archive_content_type   :string
#  archive_file_name      :string
#  archive_file_size      :integer
#  archive_updated_at     :datetime
#  created_at             :datetime         not null
#  creator_id             :integer
#  id                     :integer          not null, primary key
#  imported_at            :datetime
#  importer_id            :integer
#  lock_version           :integer          default(0), not null
#  nature                 :string           not null
#  progression_percentage :decimal(19, 4)
#  state                  :string           not null
#  updated_at             :datetime         not null
#  updater_id             :integer
#

class Import < Ekylibre::Record::Base
  belongs_to :importer, class_name: 'User'
  refers_to :nature, class_name: 'ExchangeNature'
  enumerize :state, in: [:undone, :in_progress, :errored, :aborted, :finished], predicates: true, default: :undone
  has_attached_file :archive, path: ':tenant/:class/:id/:style.:extension'
  # [VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_datetime :archive_updated_at, :imported_at, allow_blank: true, on_or_after: Time.new(1, 1, 1, 0, 0, 0, '+00:00')
  validates_numericality_of :archive_file_size, allow_nil: true, only_integer: true
  validates_numericality_of :progression_percentage, allow_nil: true
  validates_presence_of :nature, :state
  # ]VALIDATORS]
  validates_inclusion_of :progression_percentage, in: 0..100, allow_blank: true
  do_not_validate_attachment_file_type :archive

  class << self
    # Create an import and run it in background
    def launch(nature, file)
      f = File.open(file)
      import = create!(nature: nature, archive: f)
      ImportRunJob.perform_later(import.id)
      import
    end

    # Create an import and run it directly
    def launch!(nature, file, &block)
      f = File.open(file)
      import = create!(nature: nature, archive: f)
      import.run(&block)
      import
    end
  end

  def name
    nature ? nature.text : :unknown.tl
  end

  # Run an import.
  # The optional code block permit have access to progression on each check point
  def run(&_block)
    update_columns(state: :in_progress, progression_percentage: 0)
    Ekylibre::Record::Base.transaction do
      ActiveExchanger::Base.import(nature.to_sym, archive.path) do |progression, count|
        update_columns(progression_percentage: progression)
        break unless yield(progression, count) if block_given?
      end
    end
    update_columns(state: :finished, progression_percentage: 100, imported_at: Time.now, importer_id: (User.stamper.is_a?(User) ? User.stamper.id : User.stamper.is_a?(Fixnum) ? User.stamper : nil))
  rescue ActiveExchanger::Error => e
    update_columns(state: :errored, progression_percentage: 0)
    raise ActiveExchanger::Error, e.message
  end

  def runnable?
    !self.finished?
  end
end
