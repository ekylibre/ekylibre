# == Schema Information
#
# Table name: document_templates
#
#  active       :boolean       not null
#  cache        :text          
#  company_id   :integer       not null
#  country      :string(2)     
#  created_at   :datetime      not null
#  creator_id   :integer       
#  deleted      :boolean       not null
#  id           :integer       not null, primary key
#  language_id  :integer       
#  lock_version :integer       default(0), not null
#  name         :string(255)   not null
#  nature_id    :integer       not null
#  source       :text          
#  updated_at   :datetime      not null
#  updater_id   :integer       
#

class DocumentTemplate < ActiveRecord::Base
  belongs_to :company
  belongs_to :language
  belongs_to :nature, :class_name=>DocumentNature.name
  has_many :documents, :foreign_key=>:template_id

  validates_presence_of :nature_id

  attr_readonly :company_id

  include ActionView::Helpers::NumberHelper

  def before_validation
    self.cache = self.class.compile(self.source) # rescue nil
    begin
      self.cache = self.class.compile(self.source) # rescue nil
    rescue Exception => e
      self.errors.add(:source, e.message)
    end  
  end

  def validates
    errors.add(:source, 'est invalide') if self.cache.nil?
  end

  def destroyable?
    true
  end



  def print(*args)
    # Analyze parameters
    object = args[0]
    raise Exception.new("Must be an activerecord") unless object.class.ancestors.include?(ActiveRecord::Base)

    # Try to find an existing archive
    if self.nature.to_archive
      # document = self.documents.find(:first, :conditions=>["owner_id = ? and owner_type = ?", object.id, object.class.name], :order=>"created_at DESC")
      document = self.company.documents.find(:first, :conditions=>{:nature_code=>self.nature.code, :owner_id=>object.id, :owner_type=>object.class.name}, :order=>"created_at DESC")
      begin
        return document.data if document
      rescue
        
      end
    end

    # Build the PDF data
    pdf = eval(self.cache)

    # Archive the document if necessary
    if self.nature.to_archive
      document = self.archive(object, pdf, :extension=>'pdf')
    end
    
    return pdf
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
    code = self.class.compile(self.source, :debug)
    pdf = nil
    begin 
      pdf = eval(code)
    rescue Exception=>e
      doc = Ibeh.document(Hebi::Document.new, self)do |ibeh|
        ibeh.page(:a4, :margin=>[15.mm]) do |p|
          p.part 200.mm do |x|
            x.set do |s|
              s.text "Exception : "+e.inspect+"\n"+e.backtrace[0..25].join("\n")+"..."
            end
          end
        end
      end
      pdf = doc.generate
    end
    pdf
  end


  def self.compile(source, mode=:normal)
    file = "#{RAILS_ROOT}/tmp/pt_compile-"+Time.now.strftime("%Y%m%d-%H%M%S")+"-"+rand.to_s+".xml"
    File.open(file, 'wb') {|f| f.write(source)}
    xml = LibXML::XML::Document.file(file)
    template = xml.root
    # raise Exception.new template.find('*').to_a.inspect
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
    code << "doc = Ibeh.document(Hebi::Document.new, self) do |_document_|\n"
    # code << compile_element(document, '__document', mode, :skip=>true)
    document.each_element do |x|
      code << compile_element(x, '_document_', mode)
    end
    #code << compile_element(document, '__document', mode)
    code << "end\n"
    code << "doc.generate"

#     document.find('page').each do |page|
#       code += "ibeh.page(#{parameters(page, 'ERROR', mode)[0]}) do |p|\n"
      
#       page.each_element do |element|
#         name = element.name.to_sym
#         if [:table, :part].include? name 
#           code += compile_element(element, 'p', mode) 
#         elsif name == :iteration
#           code += compile_element(page, 'p', mode, :skip=>true) 
#         end
#       end
#       code += "end\n"
#     end
    

 
    
    File.delete(file)

    list = code.split("\n"); list.each_index{|x| puts((x+1).to_s.rjust(4)+": "+list[x])}
    return '('+(mode==:debug ? code : code.gsub(/\s*\n\s*/, ';'))+')'
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
        v == "true" ? "true" : "false"
      when :value
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




    def parameters(element, nvar, mode)
      name = element.name.to_sym
      attributes, parameters = {}, []
      element.attributes.to_h.collect{|k,v| attributes[k.to_sym] = v}
      (ATTRIBUTES[name]||[]).each{|attr| parameters << attr_to_s(attr, attributes.delete(attr), nvar, mode)}
      attributes.delete(:if)
      attrs = attrs_to_s(attributes, nvar, mode)
      attrs = ', '+attrs if !attrs.blank? and parameters.size>0
      return parameters.join(', ')+attrs, parameters, attributes
    end




    def compile_element(element, variable, mode, options={}) # depth=0, skip=false)
      depth = options[:depth]||0
      skip = options[:skip]||false
      code  = ''
      name = element.name.to_sym
      params, p, attrs = parameters(element, variable, mode)
      if name == :iteration
        code += "for #{p[0]} in #{p[1]}\n"
        element.each_element do |x|
          code += compile_element(x, variable, mode, :depth=>depth)||'  '
        end
        code += "end\n"
      elsif name == :image
        code += "if File.exist?((#{p[0]}).to_s)\n"
        code += "  #{variable}.#{name}(#{params})\n"
        code += "else\n"
        element.each_element do |x|
          code += compile_element(x, variable, mode, :depth=>depth)
        end
        code += "end\n"
      else
        nvar = '_r'+depth.to_s+'_'
        children = ''
        element.each_element do |x|
          children += compile_element(x, nvar, mode, :depth=>depth+1)
        end
        code = "#{variable}.#{name}(#{params})"
        code += " do |#{nvar}|\n"+children+"end" unless children.blank?
        code += "\n"
      end
      

#       if skip 
#         nvar = variable
#       else
#         code += "#{variable}.#{element.name}(#{parameters(element, variable, mode)[0]}) do |#{nvar}|\n"
#       end
#       element.each_element do |x|
#         name = x.name.to_sym
#         # puts [element.name, CHILDREN[element.name], name].inspect
#         # next unless (CHILDREN[element.name.to_sym]||[]).include?(name)
#         if CHILDREN.keys.include? name
#           code += compile_element(x, nvar, mode, :depth=>depth+1)
#         elsif name == :iteration
#           params, p, attrs = parameters(x, nvar, mode)
#           code += "  for #{p[0]} in #{p[1]}\n"
#           code += compile_element(x, nvar, mode, :depth=>depth, :skip=>true)||'  '
#           code += "  end\n"          
#         elsif name == :image
#           params, p, attrs = parameters(x, nvar, mode)
#           code += "  if File.exist?((#{p[0]}).to_s)\n"
#           code += "    #{nvar}.#{name}(#{params})\n"
#           code += "  else\n"
#           code += compile_element(x, nvar, mode, :depth=>depth, :skip=>true)
#           code += "  end\n"
#         else
#           code += "  #{nvar}.#{name}(#{parameters(x, nvar, mode)[0]})\n"
#         end
#       end
#       unless skip
#         code += "end"
#         code += " if #{element.attributes['if'].gsub(/\//,'.')}" if element.attributes['if']
#         code += "\n"
#       end
      code.gsub(/^/, '  ')
    end





  end
  

end
