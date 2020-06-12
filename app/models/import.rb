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
#  options                :jsonb
#  progression_percentage :decimal(19, 4)
#  state                  :string           not null
#  updated_at             :datetime         not null
#  updater_id             :integer
#

class Import < Ekylibre::Record::Base
  belongs_to :importer, class_name: 'User'
  enumerize :nature, in: ActiveExchanger::Base.importers.keys, i18n_scope: ['exchangers']
  enumerize :state, in: %i[undone in_progress errored aborted finished], predicates: true, default: :undone
  has_attached_file :archive, path: ':tenant/:class/:id/:style.:extension'
  # [VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates :archive_content_type, :archive_file_name, length: { maximum: 500 }, allow_blank: true
  validates :archive_file_size, numericality: { only_integer: true, greater_than: -2_147_483_649, less_than: 2_147_483_648 }, allow_blank: true
  validates :archive_updated_at, :imported_at, timeliness: { on_or_after: -> { Time.new(1, 1, 1).in_time_zone }, on_or_before: -> { Time.zone.now + 50.years } }, allow_blank: true
  validates :nature, :state, presence: true
  validates :progression_percentage, numericality: { greater_than: -1_000_000_000_000_000, less_than: 1_000_000_000_000_000 }, allow_blank: true
  # ]VALIDATORS]
  validates :progression_percentage, inclusion: { in: 0..100, allow_blank: true }
  do_not_validate_attachment_file_type :archive

  scope :finished, -> { where(state: :finished) }

  class InterruptRequest < StandardError
  end

  class << self
    # Create an import and run it in background
    def launch(nature, file, options = {})
      f = File.open(file)
      import = create!(nature: nature, archive: f, options: options)
      ImportRunJob.perform_later(import.id)
      import
    end

    # Create an import and run it directly
    def launch_result!(nature, file, options = {}, &block)
      f = File.open(file)
      import = create!(nature: nature, archive: f, options: options)
      import.run_result(&block)
    end

    def launch!(nature, file, options = {}, &block)
      launch_result!(nature, file, options, &block)
    end
    
  end

  def name
    nature.respond_to?(:text) ? nature.text : nature.to_s.humanize
  end

  def run_later
    ImportRunJob.perform_later(id)
  end

  def run(&block)
    run_result(&block).to_bool
  end
  # Run an import.
  # The optional code block allows have access to progression on each check point
  def run_result(&block)
    FileUtils.mkdir_p(progress_file.dirname)
    update_columns(state: :in_progress, progression_percentage: 0)
    File.write(progress_file, 0.to_s)

    import_options = options || {}
    import_options = import_options.merge(import_id: id)

    result = ActiveExchanger::Base.run(nature, archive.path, options: import_options) do |progression, count|
      update_columns(progression_percentage: progression)
      File.write(progress_file, progression.to_i.to_s)
      block.call(progression, count) if block.present?
    end

    importer_id = if User.stamper.is_a?(User)
                    User.stamper.id
                  elsif User.stamper.is_a?(Integer)
                    User.stamper
                  else
                    nil
                  end

    case result.state
      when :success
        update(state: :finished, progression_percentage: 100, imported_at: Time.zone.now, importer_id: importer_id)
      when :aborted
        update(state: :aborted)
      else # when :failure + other cases that should not happen
        update(state: :errored)
    end

    result
  end

  def progress_file
    Ekylibre::Tenant.private_directory.join('tmp', 'imports', "#{id}.progress")
  end

  def progress
    File.read(progress_file).to_i
  rescue
    0
  end

  def runnable?
    undone? && archive.file?
  end

  # Removing progress file is the signal to interrupt the process
  def abort
    FileUtils.rm_rf(progress_file)
    update_column(:state, :aborted)
  end

  def notify(message, interpolations = {}, options = {})
    if creator
      creator.notify(message, interpolations.merge(name: name), options.merge(target: self))
    end
  end
end
