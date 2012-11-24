# -*- coding: utf-8 -*-
# = Informations
#
# == License
#
# Ekylibre - Simple ERP
# Copyright (C) 2009-2012 Brice Texier, Thibaud Merigon
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
# == Table: document_templates
#
#  active       :boolean          not null
#  by_default   :boolean          default(TRUE), not null
#  cache        :text
#  code         :string(32)
#  country      :string(2)
#  created_at   :datetime         not null
#  creator_id   :integer
#  family       :string(32)
#  filename     :string(255)
#  id           :integer          not null, primary key
#  language     :string(3)        default("???"), not null
#  lock_version :integer          default(0), not null
#  name         :string(255)      not null
#  nature       :string(64)
#  source       :text
#  to_archive   :boolean
#  updated_at   :datetime         not null
#  updater_id   :integer
#


class DocumentTemplate < CompanyRecord
  after_save :set_by_default
  # TODO Do we keep DocumentTemplate families ?
  cattr_reader :families, :document_natures
  has_many :documents, :foreign_key=>:template_id
  #[VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_length_of :country, :allow_nil => true, :maximum => 2
  validates_length_of :language, :allow_nil => true, :maximum => 3
  validates_length_of :code, :family, :allow_nil => true, :maximum => 32
  validates_length_of :nature, :allow_nil => true, :maximum => 64
  validates_length_of :filename, :name, :allow_nil => true, :maximum => 255
  validates_inclusion_of :active, :by_default, :in => [true, false]
  validates_presence_of :language, :name
  #]VALIDATORS]
  validates_presence_of :filename
  validates_uniqueness_of :code

  include ActionView::Helpers::NumberHelper

  @@families = [:company, :relations, :accountancy, :management, :production] # :resources,

  # id is forbidden names for parameters
  @@document_natures = {
#    :journal =>          [ [:journal, Journal], [:started_on, Date], [:stopped_on, Date] ]  }
# {
    :balance_sheet =>    [ [:financial_year, FinancialYear] ],
    :entity =>           [ [:entity, Entity] ],
    :deposit =>          [ [:deposit, Deposit] ],
    :income_statement => [ [:financial_year, FinancialYear] ],
    :inventory =>        [ [:inventory, Inventory] ],
    :sales_invoice =>    [ [:sales_invoice, Sale] ],
    :journal =>          [ [:journal, Journal], [:started_on, Date], [:stopped_on, Date] ],
    :general_journal =>  [ [:started_on, Date], [:stopped_on, Date] ],
    :general_ledger =>   [ [:started_on, Date], [:stopped_on, Date] ],
    :purchase =>         [ [:purchase, Purchase] ],
    :sales =>            [ [:established_on, Date] ],
    :sales_order =>      [ [:sales_order, Sale] ],
    :stocks =>           [ [:established_on, Date] ],
    # :synthesis =>        [ [:financial_year, FinancialYear] ],
    :transport =>        [ [:transport, Transport] ]
  }

  # [:balance, :sales_invoice, :sale, :purchase, :inventory, :transport, :deposit, :entity, :journal, :ledger, :other]

  # include ActionView::Helpers::NumberHelper


  default_scope order(:name)
  scope :of_nature, lambda { |nature|
    raise ArgumentError.new("Unknown nature for a DocumentTemplate (got #{nature.inspect}:#{nature.class})") unless @@document_natures.keys.include?(nature.to_sym)
    where(:nature => nature.to_s, :active => true).order(:name)
  }


  before_validation do
    self.filename ||= 'document'
    self.cache = Templating.compile(self.source, :xil) # rescue nil
    self.by_default = true if self.class.find_all_by_nature_and_by_default(self.nature, true).size <= 0
    return true
  end

  validate do
    errors.add(:source, :invalid) if self.cache.blank?
    if self.nature != "other"
      syntax_errors = self.filename_errors
      errors.add_to_base(syntax_errors, :forced=>true) unless syntax_errors.empty?
    end
  end

  def set_by_default# (by_default=nil)
    if self.nature != 'other' and DocumentTemplate.count(:conditions=>{:by_default=>true, :nature=>self.nature}) != 1
      DocumentTemplate.update_all({:by_default=>true}, {:id=>self.id})
      DocumentTemplate.update_all({:by_default=>false}, ["id != ? and nature = ?", self.id, self.nature])
    end
  end

  protect(:on => :destroy) do
    self.documents.size <= 0
  end

  def self.families
    @@families.collect{|x| [tc('families.'+x.to_s), x.to_s]}
  end

  def self.natures
    @@document_natures.keys.collect{|x| [tc('natures.'+x.to_s), x.to_s]}.sort{|a,b| a[0].ascii<=>b[0].ascii}
  end

  def family_label
    tc('families.'+self.family) if self.family
  end

  def nature_label
    tc('natures.'+self.nature) if self.nature
  end


  # Print document without checks fast but dangerous if parameters are not checked before...
  # Use carefully
  def print_fastly!(*args)
    # Refresh cache if needed
    self.save! unless self.cache.starts_with?(Templating.preamble)

    # Try to find an existing archive
    if self.to_archive and owner.is_a?(ActiveRecord::Base)
      document = Document.where(:nature_code=>self.code, :owner_id=>owner.id, :owner_type=>owner.class.name).order("created_at DESC").first
      return document.data, document.original_name if document
    end

    # Build the PDF data
    # self.cache.split("\n").each_with_index{|l,x| puts((x+1).to_s.rjust(4)+": "+l)}
    pdf = eval(self.cache)

    # Archive the document if necessary
    document = self.archive(owner, pdf, :extension=>'pdf') if self.to_archive

    return pdf, self.compute_filename(owner)+".pdf"
  end




  # Print document raising Exceptions if necessary
  def print!(*args)
    # Refresh cache if needed
    self.save! unless self.cache.starts_with?(Templating.preamble)

    # Analyze and cleans parameters
    parameters = @@document_natures[self.nature.to_sym]
    raise StandardError.new(tc(:unvalid_nature)) if parameters.nil?
    if args[0].is_a? Hash
      hash = args[0]
      parameters.each_index do |i|
        args[i] = hash[parameters[i][0]]||hash["p"+i.to_s]
      end
    end
    raise ArgumentError.new("Bad number of arguments, #{args.size} for #{parameters.size}") if args.size != parameters.size

    parameters.each_index do |i|
      args[i] = parameters[i][1].find_by_id(args[i].to_s.to_i) if parameters[i][1].ancestors.include?(ActiveRecord::Base) and not args[i].is_a? parameters[i][1]
      args[i] = args[i].to_date if args[i].class == String and parameters[i][1] == Date
      raise ArgumentError.new("#{parameters[i][1].name} expected, got #{args[i].inspect}") unless args[i].class == parameters[i][1]
    end

    # Try to find an existing archive
    if self.to_archive and args[0].class.ancestors.include?(ActiveRecord::Base)
      document = Document.where(:nature_code=>self.code, :owner_id=>owner.id, :owner_type=>owner.class.name).order("created_at DESC").first
      return document.data, document.original_name if document
    end

    # Build the PDF data
    begin
      pdf = eval(self.cache)
    rescue Exception => e
      puts e.message+"\nCache:\n"+self.cache
      raise e
    end

    # Archive the document if necessary
    document = self.archive(owner, pdf, :extension=>'pdf') if self.to_archive

    return pdf, self.compute_filename(owner)+".pdf"
  end


  # Print document or exception if necessary
  def print(*args)
    begin
      return self.print!(*args)
    rescue Exception=>e
      return self.class.error_document(e)
    end
  end


  def filename_errors
    errors = []
    begin
      klass = @@document_natures[self.nature.to_sym][0][1]
      columns = klass.content_columns.collect{|x| x.name.to_s}.sort
      self.filename.gsub(/\[\w+\]/) do |word|
        unless columns.include?(word[1..-2])
          errors << tc(:error_attribute, :value=>word, :possibilities=>columns.collect { |column| column+" ("+klass.human_attribute_name(column)+")" }.join(", "))
        end
        "*"
      end
    rescue
      #   errors << tc(:nature_do_not_allow_to_use_attributes)
    end
    return errors
  end

  def compute_filename(object)
    if self.nature == "other" #||"card"
      filename = self.filename
    elsif self.filename_errors.empty?
      filename = self.filename.gsub(/\[\w+\]/) do |word|
        #raise Exception.new "2"+filename.inspect
        object.attributes[word[1..-2]].to_s rescue ""
      end
    else
      return tc(:invalid_filename)
    end
    return filename
  end

  def archive(owner, data, attributes={})
    document = self.documents.new(attributes.merge(:owner_id=>owner.id, :owner_type=>owner.class.name))
    method_name = [:document_name, :number, :code, :name, :id].detect{|x| owner.respond_to?(x)}
    document.printed_at = Time.now
    document.extension ||= 'bin'
    document.subdir = Date.today.strftime('%Y-%m')
    document.original_name = owner.send(method_name).to_s.simpleize+'.'+document.extension.to_s
    document.filename = owner.send(method_name).to_s.codeize+'-'+document.printed_at.to_i.to_s(36).upper+'-'+Document.generate_key+'.'+document.extension.to_s
    document.filesize = data.length
    document.sha256 = Digest::SHA256.hexdigest(data)
    document.crypt_mode = 'none'
    if document.save
      FileUtils.mkdir_p(document.path)
      File.open(document.file_path, 'wb') {|f| f.write(data) }
    else
      raise Exception.new(document.errors.inspect)
    end
    return document
  end


  def sample
    self.save!
    code = Templating.compile(self.source, :xil, :mode=>:debug)
    pdf = nil
    # code.split("\n").each_with_index{|l,x| puts((x+1).to_s.rjust(4)+": "+l)}
    begin
      pdf = eval(code)
    rescue Exception=>e
      pdf = DocumentTemplate.error_document(e)
    end
    pdf
  end


  # Produces a generic document with the trace of the thrown exception
  def self.error_document(exception)
    Templating::Writer.generate do |doc|
      doc.page(:size=>"A4", :margin=>15.mm) do |p|
        if exception.is_a? Exception
          p.slice do |s|
            s.text("Exception: "+exception.inspect)
          end
          for line in exception.backtrace
            p.slice do |s|
              s.text(line)
            end
          end
        else
          p.slice do |s|
            s.text("Error: "+exception.inspect, :width=>180.mm)
          end
        end
      end
    end
  end

  def self.load_defaults
    language = Entity.of_company.language
    files_dir = Rails.root.join("config", "locales", ::I18n.locale.to_s, "prints")
    for family, templates in ::I18n.translate('models.company.default.document_templates')
      for template, attributes in templates
        next unless File.exist? files_dir.join("#{template}.xml")
        #begin
        File.open(files_dir.join("#{template}.xml"), "rb:UTF-8") do |f|
          attributes[:name] ||= I18n::t('models.document_template.natures.'+template.to_s)
          attributes[:name] = attributes[:name].to_s
          attributes[:nature] ||= template.to_s
          attributes[:filename] ||= "File"
          attributes[:to_archive] = true if attributes[:to_archive] == "true"
          if RUBY_VERSION =~ /^1\.9/
            attributes[:source] = f.read.force_encoding('UTF-8')
          else
            attributes[:source] = f.read
          end
          code = attributes[:name].to_s.codeize[0..7]
          doc = self.find_by_code(code)
          doc ||= self.new
          doc.attributes = HashWithIndifferentAccess.new(:active=>true, :language=>language, :country=>'fr', :family=>family.to_s, :code=>code, :by_default=>false).merge(attributes)
          # doc["source"].force_encoding!('UTF-8') if RUBY_VERSION =~ /^1\.9/
          doc.save!
        end
        #rescue
        #end
      end
    end

  end

end
