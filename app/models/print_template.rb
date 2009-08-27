# == Schema Information
#
# Table name: print_templates
#
#  cache        :text          
#  company_id   :integer       not null
#  country      :string(8)     
#  created_at   :datetime      not null
#  creator_id   :integer       
#  id           :integer       not null, primary key
#  language_id  :integer       
#  lock_version :integer       default(0), not null
#  name         :string(255)   not null
#  source       :text          
#  updated_at   :datetime      not null
#  updater_id   :integer       
#

class PrintTemplate < ActiveRecord::Base
  belongs_to :company
  belongs_to :language

  attr_readonly :company_id

  def before_validation
    self.cache = self.class.compile(self.source) rescue nil
  end

  def validates
    errors.add(:source, 'est invalide') if self.cache.nil?
  end

  def destroyable?
    true
  end

  def self.compile(source)
    file = "#{RAILS_ROOT}/tmp/pt_compile-"+Time.now.strftime("%Y%m%d-%H%M%S")+"-"+rand.to_s+".xml"
    File.open(file, 'wb') {|f| f.write(source)}
    xml = LibXML::XML::Document.file(file)
    template = xml.root
    # raise Exception.new template.find('*').to_a.inspect
    document = template.find('document')[0]
    code = ''    
    code << "sale_order = SaleOrder.first\n"
    code << "doc=Ibeh.document(Hebi::Document.new, self) do |ibeh|\n"

    document.find('page').each do |page|
      code += "ibeh.page(#{parameters(page, 'ERROR')[0]}) do |p|\n"
      page.each_element do |element|
        name = element.name.to_sym
        if [:table, :part].include? name
#           if name == :part
#             code += "  p.#{element.name}() do |x|\n"
#             element.find('set').each do |set|
#               code += compile_element(set).gsub(/^/, '  ')
#             end
#             code += "  end"
#             code += " if #{element.attributes['if'].gsub(/\//,'.')}" if element.attributes['if']
#             code += "\n"
#           else
            code += compile_element(element, 'p')
#          end
        end
      end
      code += "end\n"
    end
    
    code << "end\n"
    code << "File.open('/tmp/test.pdf', 'wb') {|f| f.write(doc.generate)}\n"
    #code << "@current_company.archive(@template, pdf);pdf"

    list = code.split("\n"); list.each_index{|x| puts((x+1).to_s.rjust(4)+": "+list[x])}

    eval(code)
    return code
  end

  private


  class << self
    
    SET_ELEMENTS = {
      :page=>[:format],
      :part=>[:height],
      :table=>[:collection],
      :list=>[:collection],
      :column=>[:label, :property, :width],
      :set=>[],
      :font=>[],
      :text=>[:value],
      :cell=>[:value, :width],
      :rectangle=>[:width, :height],
      :line=>[:path],
      :image=>[:src]
    }
    


    def str_to_measure(string, nvar)
      string = string.to_s
      if string.match(/\d+(\.\d+)?mm/)
        string[0..-3]+'.mm'
      elsif string.match(/\d+(\.\d+)?\%/)
        string[0..-2].to_f == 100 ? "#{nvar}.width" : (string[0..-2].to_f/100).to_s+"*#{nvar}.width"
      elsif string.match(/\d+(\.\d+)?/)
        string
      else
        "((0))"
      end
    end

    def attr_to_s(k, v, nvar)
      case(k)
      when :align, :valign then
        ":#{v.strip.gsub(/\s+/,'_')}"
      when :top, :left, :width, :height, :size then
        str_to_measure(v, nvar)
      when :margin, :padding then
        '['+v.strip.split(/\s+/).collect{|m| str_to_measure(m, nvar)}.join(', ')+']'
      when :collection then
        v
      when :property then
        "'"+v.gsub(/\//, '.')+"'"
      when :resize, :fixed, :bold, :italic then
        v == "true" ? "true" : "false"
      when :value
        v = v.inspect.gsub(/\{\{[^\}]+\}\}/) do |m|
          data_path = m[2..-3]
          address = data_path.split('?')[0].gsub('/','.')
          "\"+#{address}.to_s+\""
        end
        v = v[3..-1] if v.match(/^\"\"\+/)
        v = v[0..-4] if v.match(/\+\"\"$/)
        v
      when :path
        '['+v.split(/\s*\;\s*/).collect{|point| '['+point.split(/\s*\,\s*/).collect{|m| str_to_measure(m, nvar)}.join(', ')+']'}.join(', ')+']'
      else
        v.inspect
      end
    end




    def parameters(element, nvar)
      name = element.name.to_sym
      attributes, parameters = {}, []
      element.attributes.to_h.collect{|k,v| attributes[k.to_sym] = v}
      (SET_ELEMENTS[name]||[]).each{|attr| parameters << attr_to_s(attr, attributes.delete(attr), nvar)}
      attributes.delete(:if)
      attrs = attrs_to_s(attributes, nvar)
      attrs = ', '+attrs if !attrs.blank? and parameters.size>0
      return parameters.join(', ')+attrs, parameters, attributes
    end




    def attrs_to_s(attrs, nvar)
      attrs.collect{|k,v| ":#{k}=>#{attr_to_s(k, v, nvar)}"}.join(', ')
    end
    
    def compile_element(element, variable='x', depth=0, skip=false)
      nvar = 'r'+depth.to_s
      code  = ''

      code += "#{variable}.#{element.name}(#{parameters(element, variable)[0]}) do |#{nvar}|\n" unless skip
      element.each_element do |x|
        name = x.name.to_sym
        if name == :set
          code += compile_element(x, nvar, depth+1)
        elsif name == :image
          params, p, attrs = parameters(x,nvar)
          code += "  if File.exist?(#{p[0]})\n"
          code += "    #{nvar}.#{name}(#{params})\n"
          code += "  else\n"
          code += compile_element(x, nvar, depth, true)
          code += "  end\n"        
        else
          code += "  #{nvar}.#{name}(#{parameters(x,nvar)[0]})\n"
        end
      end
      unless skip
        code += "end"
        code += " if #{element.attributes['if'].gsub(/\//,'.')}" if element.attributes['if']
        code += "\n"
      end
      code.gsub(/^/, '  ')
    end
  end
  

end
