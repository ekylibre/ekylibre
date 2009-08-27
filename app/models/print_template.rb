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
    document.find('page').each do |page|
      code += "page(:#{page.attributes['format']||'a4'}) do |p|\n"
      page.each_element do |element|
        name = element.name.to_sym
        if [:table, :part].include? name
          if name == :part
            code += "  p.#{element.name}() do |x|\n"
            element.find('set').each do |set|
              code += compile_element(set).gsub(/^/, '  ')
            end
            code += "  end"
            code += " if #{element.attributes['if']}" if element.attributes['if']
            code += "\n"
          else
            code += compile_element(element, 'p')
          end
        end
      end
      code += "end\n"
    end
    

    return code
  end

  private


  class << self
    
    SET_ELEMENTS = {
      :column=>[:label, :value, :width],
      :font=>[],
      :text=>[:value],
      :cell=>[:value, :width],
      :rectangle=>[:width, :height],
      :line=>[:points],
      :image=>[:src]
    }
    

    def attrs_to_s(attrs)
      attrs.collect do |k,v|
        ":#{k}=>"+
          case(k)
          when :align, :valign then
            ":#{v.strip.gsub(/\s+/,'_')}"
          when :top, :left, :width, :height, :size then
            if v.match(/\d+(\.\d+)?mm/)
              v[0..-3]+'.mm'
            elsif v == "width" or v.match(/\d+(\.\d+)?/)
              v
            end
          when :resize, :fixed, :bold, :italic then
            v == "true" ? "true" : "false"
          else
            v.inspect
          end
      end.join(', ')
    end
    
    def compile_element(element, variable='x', depth=0, skip=false)
      nvar = 'r'+depth.to_s
      code  = ''
      code += "#{variable}.#{element.name}() do |#{nvar}|\n" unless skip
      element.each_element do |x|
      name = x.name.to_sym
        attributes, parameters = {}, []
        x.attributes.to_h.collect{|k,v| attributes[k.to_sym] = v }
        (SET_ELEMENTS[name]||[]).each{|attr| parameters << attributes.delete(attr).inspect}
        attrs = attrs_to_s(attributes)
        attrs = ', '+attrs unless attrs.blank?
        if name == :set
          code += compile_element(x, nvar, depth+1)
        elsif name == :image
          code += "  if File.exist?(#{parameters[0]})\n"
          code += "    #{nvar}.#{name}(#{parameters.join(', ')}#{attrs})\n"
          code += "  else\n"
          code += compile_element(x, nvar, depth, true)
          code += "  end\n"        
        else
          code += "  #{nvar}.#{name}(#{parameters.join(', ')}#{attrs})\n"
        end
      end
      unless skip
        code += "end"
        code += " if #{element.attributes['if']}" if element.attributes['if']
        code += "\n"
      end
      code.gsub(/^/, '  ')
    end
  end
  

end
