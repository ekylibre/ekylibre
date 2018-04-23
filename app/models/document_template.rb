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
# == Table: document_templates
#
#  active       :boolean          default(FALSE), not null
#  archiving    :string           not null
#  by_default   :boolean          default(FALSE), not null
#  created_at   :datetime         not null
#  creator_id   :integer
#  formats      :string
#  id           :integer          not null, primary key
#  language     :string           not null
#  lock_version :integer          default(0), not null
#  managed      :boolean          default(FALSE), not null
#  name         :string           not null
#  nature       :string           not null
#  updated_at   :datetime         not null
#  updater_id   :integer
#

# Sources are stored in :private/reporting/:id/content.xml
class DocumentTemplate < Ekylibre::Record::Base
  enumerize :archiving, in: %i[none_of_template first_of_template last_of_template none first last], default: :none, predicates: { prefix: true }
  refers_to :language
  refers_to :nature, class_name: 'DocumentNature'
  has_many :documents, class_name: 'Document', foreign_key: :template_id, dependent: :nullify, inverse_of: :template
  # [VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates :active, :by_default, :managed, inclusion: { in: [true, false] }
  validates :archiving, :language, :nature, presence: true
  validates :formats, length: { maximum: 500 }, allow_blank: true
  validates :name, presence: true, length: { maximum: 500 }
  # ]VALIDATORS]
  validates :language, length: { allow_nil: true, maximum: 3 }
  validates :archiving, :nature, length: { allow_nil: true, maximum: 60 }
  validates :nature, inclusion: { in: nature.values }

  selects_among_all scope: :nature

  # default_scope order(:name)
  scope :of_nature, lambda { |*natures|
    natures.flatten!
    natures.compact!
    return none unless natures.respond_to?(:any?) && natures.any?
    invalids = natures.select { |nature| Nomen::DocumentNature[nature].nil? }
    if invalids.any?
      raise ArgumentError, "Unknown nature(s) for a DocumentTemplate: #{invalids.map(&:inspect).to_sentence}"
    end
    where(nature: natures, active: true).order(:name)
  }

  scope :find_active_template, ->(name) do
    where(active: true)
      .where(name.is_a?(Integer) ? { id: name.to_i } : { by_default: true, nature: name.to_s })
      .first
  end

  protect(on: :destroy) do
    documents.any?
  end

  before_validation do
    # Check that given formats are all known
    unless formats.empty?
      self.formats = formats.to_s.downcase.strip.split(/[\s\,]+/).delete_if do |f|
        !Ekylibre::Reporting.formats.include?(f)
      end.join(', ')
    end
  end

  after_save do
    # Install file after save only
    if @source
      FileUtils.mkdir_p(source_path.dirname)
      File.open(source_path, 'wb') do |f|
        # Updates source to make it working
        begin
          document = Nokogiri::XML(@source) do |config|
            config.noblanks.nonet.strict
          end
          # Removes comments
          document.xpath('//comment()').remove
          # Updates template
          if document.root && document.root.namespace && document.root.namespace.href == 'http://jasperreports.sourceforge.net/jasperreports'
            if template = document.root.xpath('xmlns:template').first
              logger.info "Update <template> for document template #{nature}"
              template.children.remove
              style_file = Ekylibre::Tenant.private_directory.join('corporate_identity', 'reporting_style.xml')
              # TODO: find a way to permit customization for users to restore that
              if true # unless style_file.exist?
                FileUtils.mkdir_p(style_file.dirname)
                FileUtils.cp(Rails.root.join('config', 'corporate_identity', 'reporting_style.xml'), style_file)
              end
              template.add_child(Nokogiri::XML::CDATA.new(document, style_file.relative_path_from(source_path.dirname).to_s.inspect))
            else
              logger.info "Cannot find and update <template> in document template #{nature}"
            end
          end
          # Writes source
          f.write(document.to_s)
        end
      end
      # Remove .jasper file to force reloading
      Dir.glob(source_path.dirname.join('*.jasper')).each do |file|
        FileUtils.rm_f(file)
      end
    end
  end

  # Updates archiving methods of other templates of same nature
  after_save do
    if archiving.to_s =~ /\_of\_template$/
      self.class.where('nature = ? AND NOT archiving LIKE ? AND id != ?', nature, '%_of_template', id).update_all("archiving = archiving || '_of_template'")
    else
      self.class.where('nature = ? AND id != ?', nature, id).update_all(archiving: archiving)
    end
  end

  # Always after protect on destroy
  after_destroy do
    FileUtils.rm_rf(source_dir) if source_dir.exist?
  end

  # Install the source of a document template
  # with all its dependencies
  attr_writer :source

  # Returns source value
  attr_reader :source

  # Returns the expected dir for the source file
  def source_dir
    self.class.sources_root.join(id.to_s)
  end

  # Returns the expected path for the source file
  def source_path
    source_dir.join('content.xml')
  end

  # Print a document with the given datasource and return raw data
  # Store if needed by template
  # @param datasource XML representation of data used by the template
  def print(datasource, key, format = :pdf, options = {})
    # Load the report
    report = Beardley::Report.new(source_path, locale: 'i18n.iso2'.t)
    # Call it with datasource
    data = report.send("to_#{format}", datasource)
    # Archive the document according to archiving method. See #document method.
    document(data, key, format, options)
    # Returns only the data (without filename)
    data
  end

  # Export a document with the given datasource and return path file
  # Store if needed by template
  # @param datasource XML representation of data used by the template
  def export(datasource, key, format = :pdf, options = {})
    # Load the report
    report = Beardley::Report.new(source_path, locale: 'i18n.iso2'.t)
    # Call it with datasource
    path = Pathname.new(report.to_file(format.to_sym, datasource))
    # Archive the document according to archiving method. See #document method.
    if document = self.document(path, key, format, options)
      FileUtils.rm_rf(path)
      path = document.file.path(:original)
    end
    # Returns only the path
    path
  end

  # Returns the list of formats of the templates
  def formats
    (self['formats'].blank? ? Ekylibre::Reporting.formats : self['formats'].strip.split(/[\s\,]+/))
  end

  def formats=(value)
    self['formats'] = (value.is_a?(Array) ? value.join(', ') : value.to_s)
  end

  # Archive the document using the given archiving method
  def document(data_or_path, key, _format, options = {})
    return nil if archiving_none? || archiving_none_of_template?

    # Gets historic of document
    archives = Document.where(nature: nature, key: key).where.not(template_id: nil)
    archives_of_template = archives.where(template_id: id)

    # Checks if archiving is expected
    return nil unless (archiving_first? && archives.empty?) ||
                      (archiving_first_of_template? && archives_of_template.empty?) ||
                      archiving.to_s =~ /\A(last|all)(\_of\_template)?\z/

    # Lists last documents to remove after archiving
    removables = []
    if archiving_last?
      removables = archives.pluck(:id)
    elsif archiving_last_of_template?
      removables = archives_of_template.pluck(:id)
    end

    # Creates document if not exist
    document = Document.create!(nature: nature, key: key, name: (options[:name] || tc('document_name', nature: nature.l, key: key)), file: File.open(data_or_path), template_id: id)

    # Removes useless docs
    Document.destroy removables

    document
  end

  @@load_path = []
  mattr_accessor :load_path

  class << self
    # Print document with default active template for the given nature
    # Returns nil if no template found.
    def print(nature, datasource, key, format = :pdf, options = {})
      if template = find_by(nature: nature, by_default: true, active: true)
        return template.print(datasource, key, format, options)
      end
      nil
    end

    # Returns the root directory for the document templates's sources
    def sources_root
      Ekylibre::Tenant.private_directory.join('reporting')
    end

    # Compute fallback chain for a given document nature
    def template_fallbacks(nature, locale)
      stack = []
      load_path.each do |path|
        root = path.join(locale, 'reporting')
        stack << root.join("#{nature}.xml")
        stack << root.join("#{nature}.jrxml")
        fallback = {
          sales_order: :sale,
          sales_estimate: :sale,
          sales_invoice: :sale,
          purchases_estimate: :purchases_order
        }[nature.to_sym]
        if fallback
          stack << root.join("#{fallback}.xml")
          stack << root.join("#{fallback}.jrxml")
        end
      end
      stack
    end

    # Loads in DB all default document templates
    def load_defaults(options = {})
      locale = (options[:locale] || Preference[:language] || I18n.locale).to_s
      Ekylibre::Record::Base.transaction do
        manageds = where(managed: true).select(&:destroyable?)
        nature.values.each do |nature|
          if source = template_fallbacks(nature, locale).detect(&:exist?)
            File.open(source, 'rb:UTF-8') do |f|
              unless template = find_by(nature: nature, managed: true)
                template = new(nature: nature, managed: true, active: true, by_default: false, archiving: 'last')
              end
              manageds.delete(template)
              template.attributes = { source: f, language: locale }
              template.name ||= template.nature.l
              template.save!
            end
            Rails.logger.info "Load a default document template #{nature}"
          else
            Rails.logger.warn "Cannot load a default document template #{nature}: No file found at #{source}"
          end
        end
        destroy(manageds.map(&:id))
      end
      true
    end
  end
end

# Load default path
DocumentTemplate.load_path << Rails.root.join('config', 'locales')
