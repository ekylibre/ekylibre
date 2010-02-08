# = Informations
# 
# == License
# 
# Ekylibre - Simple ERP
# Copyright (C) 2009-2010 Brice Texier, Thibaud Mérigon
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
#  cache        :text             
#  code         :string(32)       
#  company_id   :integer          not null
#  country      :string(2)        
#  created_at   :datetime         not null
#  creator_id   :integer          
#  default      :boolean          default(TRUE), not null
#  deleted      :boolean          not null
#  family       :string(32)       
#  filename     :string(255)      
#  id           :integer          not null, primary key
#  language_id  :integer          
#  lock_version :integer          default(0), not null
#  name         :string(255)      not null
#  nature       :string(20)       
#  source       :text             
#  to_archive   :boolean          
#  updated_at   :datetime         not null
#  updater_id   :integer          
#

# -*- coding: utf-8 -*-
class DocumentTemplate < ActiveRecord::Base
  belongs_to :company
  belongs_to :language
  
  has_many :documents, :foreign_key=>:template_id

  validates_uniqueness_of :code, :scope=>:company_id

  attr_readonly :company_id

  @@families = [:company, :relations, :accountancy, :management, :production] # :resources, 

  PREAMBLE = "#1.1\n"


  # id is forbidden names for parameters
  @@document_natures = {
    :balance_sheet =>    [ [:financialyear, Financialyear] ],
    :entity =>           [ [:entity, Entity] ], 
    :embankment =>       [ [:embankment, Embankment] ],
    :income_statement => [ [:financialyear, Financialyear] ],
    :inventory =>        [ [:inventory, Inventory] ], 
    :invoice =>          [ [:invoice, Invoice] ],
    :journal =>          [ [:journal, Journal], [:started_on, Date], [:stopped_on, Date] ],
    :purchase_order =>   [ [:sale_order, PurchaseOrder] ], 
    :sale_order =>       [ [:sale_order, SaleOrder] ],
    :stocks =>           [ [:established_on, Date] ],
    # :synthesis =>        [ [:financialyear, Financialyear] ],
    :transport =>        [ [:transport, Transport] ]
  }

    #[:balance, :invoice, :sale_order, :purchase_order, :inventory, :transport, :embankment, :entity, :journal, :ledger, :other] 

  include ActionView::Helpers::NumberHelper


  def before_validation
    self.cache = self.class.compile(self.source) # rescue nil
    self.default = true if self.company.document_templates.find_all_by_nature_and_default(self.nature, true).size <= 0
  end

  def validate
    errors.add(:source, :invalid) if self.cache.blank?
    if self.nature != "other"
      syntax_errors = self.filename_errors
      errors.add_to_base(syntax_errors) unless syntax_errors.empty?
    end
  end

  def after_save
    DocumentTemplate.update_all({:default=>false}, ["company_id = ? and id != ? and nature = ?", self.company_id, self.id, self.nature]) if self.default and self.nature != 'other'
  end

  def destroyable?
    true
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

  # Print document raising Exceptions if necessary
  def print!(*args)
    # Refresh cache if needed
    self.save! unless self.cache.starts_with?(PREAMBLE)

    # Analyze and cleans parameters
    parameters = @@document_natures[self.nature.to_sym]
    raise StandardError.new(tc(:unvalid_nature)) if parameters.nil?
    raise ArgumentError.new("Bad number of arguments, #{args.size} for #{parameters.size}") if args.size != parameters.size
    if args[0].is_a? Hash
      hash = args[0]
      parameters.each_index do |i|
        args[i] = hash[parameters[i][0]]||hash["p"+i.to_s]
      end
    end

    parameters.each_index do |i|
      args[i] = parameters[i][1].find_by_id_and_company_id(args[i].to_s.to_i, self.company_id) if parameters[i][1].ancestors.include?(ActiveRecord::Base) and not args[i].is_a? parameters[i][1]
      raise ArgumentError.new("#{parameters[i].name} expected, got #{args[i].inspect}") unless args[i].class != parameters[i]
    end

    # Try to find an existing archive
    owner = args[0].class.ancestors.include?(ActiveRecord::Base) ? args[0] : self.company
    if self.to_archive
      document = self.company.documents.find(:first, :conditions=>{:nature_code=>self.code, :owner_id=>owner.id, :owner_type=>owner.class.name}, :order=>"created_at DESC")
      return document.data, document.original_name if document
    end
    
    # Build the PDF data
    pdf = eval(self.cache)

    # Archive the document if necessary
    document = self.archive(owner, pdf, :extension=>'pdf') if self.to_archive

    return pdf, self.compute_filename(owner)+".pdf"
  end


  # Print document or exception if necessary
  def print(*args)
    begin
      self.print!(*args)
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
          errors << tc(:error_attribute, :value=>word, :possibilities=>columns.collect { |column| column+" ("+I18n::t('activerecord.attributes.'+klass.name.underscore+'.'+column)+")" }.join(", "))
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
    document = self.documents.new(attributes.merge(:company_id=>owner.company_id, :owner_id=>owner.id, :owner_type=>owner.class.name))
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
      File.makedirs(document.path)
      File.open(document.file_path, 'wb') {|f| f.write(data) }
    else
      raise Exception.new(document.errors.inspect)
    end
    return document
  end


  def sample
    self.save!
    code = self.class.compile(self.source, :debug)
    pdf = nil
    list = code.split("\n"); list.each_index{|x| puts((x+1).to_s.rjust(4)+": "+list[x])}
    begin 
      pdf = eval(code)
    rescue Exception=>e
      pdf = DocumentTemplate.error_document(e)
    end
    pdf
  end

  def self.error_document(e)
    Ibeh.document(Hebi::Document.new) do |ibeh|
      ibeh.page(:a4, :margin=>[15.mm]) do |p|
        p.part(200.mm) do |x|
          x.set do |s|
            if e.is_a? Exception
              s.text "Exception : "+e.inspect+"\n"+e.backtrace[0..25].join("\n")+"..."
            else
              s.text "Erreur : "+e.inspect
            end
          end
        end
      end
    end.generate    
  end


  def self.compile(source, mode=:normal)
    xml = XML::Parser.io(StringIO.new(source.to_s)).parse
    template = xml.root
    code = ''
    i = 0
    unless mode == :debug
      parameters = template.find('parameters/parameter')
      if parameters.size > 0
        code << "raise ArgumentError.new('Unvalid number of argument') if args.size != #{parameters.size}\n"
        parameters.each do |p|
          code << "#{p.attributes['name']} = args[#{i}]\n"
          i+=1
        end
      end
    end
    document = template.find('document')[0]
    code << "doc = Ibeh.document(Hebi::Document.new) do |__d|\n"
    code << compile_children(document, '__d', mode)
    code << "end\n"
    code << "x = doc.generate\n"
    # list = code.split("\n"); list.each_index{|x| puts((x+1).to_s.rjust(4)+": "+list[x])}
    
    return PREAMBLE+'('+(mode==:debug ? code : code.gsub(/\s*\n\s*/, ';'))+')'
  end


  private

  class << self
    
    ATTRIBUTES = {
      :page=>[:format],
      :part=>[:height],
      :table=>[:collection],
      :list=>[:collection],
      :column=>[:label, :property, :width],
      :set=>[],
      :font=>[],
      :iteration=>[:variable, :collection],
      :text=>[:value],
      :cell=>[:value, :width],
      :rectangle=>[:width, :height],
      :line=>[:path],
      :image=>[:value, :width, :height]
    }
    
    CHILDREN = {
      :document=>[:page, :iteration],
      :page=>[:part, :table, :iteration],
      :part=>[:set, :iteration],
      :table=>[:column],
      :set=>[:set, :iteration, :font, :text, :cell, :rectangle, :line, :image, :list]
    }
    

    def str_to_measure(string, nvar)
      string = string.to_s
      m = if string.match(/\-?\d+(\.\d+)?mm/)
            string[0..-3]+'.mm'
          elsif string.match(/\-?\d+(\.\d+)?\%/)
            string[0..-2].to_f == 100 ? "#{nvar}.width" : (string[0..-2].to_f/100).to_s+"*#{nvar}.width"
          elsif string.match(/\-?\d+(\.\d+)?/)
            string
          else
            " (0) "
          end
      m = '('+m+')' if m.match(/^\-/)
      return m
    end

    def attrs_to_s(attrs, nvar, mode)
      attrs.collect{|k,v| ":#{k}=>#{attr_to_s(k, v, nvar, mode)}"}.join(', ')
    end
    
    def attr_to_s(k, v, nvar, mode)
      case(k)
      when :align, :valign, :numeric then
        ":#{v.strip.gsub(/\s+/,'_')}"
      when :top, :left, :right, :width, :height, :size, :border_width then
        str_to_measure(v, nvar)
      when :margin, :padding then
        '['+v.strip.split(/\s+/).collect{|m| str_to_measure(m, nvar)}.join(', ')+']'
      when :border then
        border = v.strip.split(/\s+/)
        raise Exception.new("Attribute border malformed: #{v.inspect}. Ex.: '1mm solid #123456'") if border.size!=3
        "{:width=>#{str_to_measure(border[0], nvar)}, :style=>:#{border[1]}, :color=>#{border[2].inspect}}"
      when :collection then
        mode==:debug ? "[]" : v
      when :format
        if v.to_s.match(/x/)
          v.to_s.split(/x/)[0..1].collect{|x| str_to_measure(x.strip)}
        else
          ':'+v.to_s.lower
        end
      when :property then
        "'"+v.gsub(/\//, '.')+"'"
      when :resize, :fixed, :bold, :italic then
        v.lower == "true" ? "true" : "false"
      when :value, :label
        v = v.inspect.gsub(/\{\{[^\}]+\}\}/) do |m|
          data = m[2..-3].to_s.split('?')
          datum = data[0].gsub('/', '.')
          datum = case data[1].to_s.split('=')[0]
                  when 'format'
                    "::I18n.localize(#{datum}, :format=>:legal)"
                  when 'numeric'
                    "number_to_currency(#{datum}, :separator=>',', :delimiter=>' ', :unit=>'', :precision=>2)"
                  else
                    datum
                  end
          (mode==:debug ? "[VALUE]" : "\"+#{datum}.to_s+\"")
        end
        v = v[3..-1] if v.match(/^\"\"\+/)
        v = v[0..-4] if v.match(/\+\"\"$/)
        v
      when :path
        '['+v.split(/\s*\;\s*/).collect{|point| '['+point.split(/\s*\,\s*/).collect{|m| str_to_measure(m, nvar)}.join(', ')+']'}.join(', ')+']'
      when :variable
        v.to_s.strip
      else
        v.inspect
      end
    end


    def parameters(element, variable, mode)
      name = element.name.to_sym
      attributes, parameters = {}, []
      element.attributes.to_h.collect{|k,v| attributes[k.to_sym] = v}
      attributes[:value] ||= element.content if name == :text
      (ATTRIBUTES[name]||[]).each{|attr| parameters << attr_to_s(attr, attributes.delete(attr), variable, mode)}
      attributes.delete(:if)
      attrs = attrs_to_s(attributes, variable, mode)
      attrs = ', '+attrs if !attrs.blank? and parameters.size>0
      return parameters.join(', ')+attrs, parameters, attributes
    end

    # Call code generation function for each children
    def compile_children(element, variable, mode, depth=0)
      code = ''
      element.each_element do |x|
        code += compile_element(x, variable, mode, depth)||'  '
      end
      code
    end

    # Generate code for given element
    def compile_element(element, variable, mode, depth=0)
      code  = ''
      name = element.name.to_sym
      params, p, attrs = parameters(element, variable, mode)
      if name == :iteration
        code += "for #{p[0]} in #{p[1]}\n"
        code += compile_children(element, variable, mode, depth)
        code += "end"
      elsif name == :image
        code += "if File.exist?((#{p[0]}).to_s)\n"
        code += "  #{variable}.#{name}(#{params})\n"
        code += "else\n"
        code += compile_children(element, variable, mode, depth)
        code += "end"
      else
        nvar = "_#{depth}"
        children = compile_children(element, nvar, mode, depth+1)
        code += "#{variable}.#{name}(#{params})"
        code += "do |#{nvar}|\n"+children+"end" unless children.blank?
      end

      # Encapsulation si condition
      code = "if #{element.attributes['if'].gsub(/\//,'.')}\n#{code.gsub(/^/,'  ')}\nend" if element.attributes['if'] and mode != :debug
      code += "\n"
      code.gsub(/^/, '  ')
    end

  end
  

end
