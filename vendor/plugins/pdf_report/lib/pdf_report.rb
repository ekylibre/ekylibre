
# This module groups the different methods allowing to obtain a PDF document.

module PdfReport

  def self.included (base)
    base.extend(ClassMethods)
  end

  module ClassMethods
    
    require 'rexml/document'
    include REXML
    require 'digest/md5'
    require 'rfpdf'
    
    #XRL_template = 'template'
    XRL_LOOP = 'loop'
    XRL_INFOS = 'infos'
    XRL_INFO = 'info'
    XRL_BLOCK = 'block'
    XRL_TEXT = 'text'
    XRL_IMAGE = 'image'
    XRL_RULE = 'rule'

    # this function begins to analyse the template extracting the main characteristics of
    # the Pdf document as the title, the orientation, the format, the unit ... 
    def analyze_template(template, name, id)
      document = Document.new(template)
      document_root = document.root
      va_r = 'mm'
      raise Exception.new("Only SQL") unless document_root.attributes['query-standard']||'sql' == 'sql'   
      code = 'def render_report_'+name+'(id)'+"\n"
      
      raise Exception.new("Bad orientation in the template") unless document_root.attributes['orientation'] || 'portrait' == 'portrait'
      
      pdf='pdf'
      
      code += pdf+"=FPDF.new('P','"+ document_root.attributes['unit']+"','" + document_root.attributes['format']+ "')\n"
      
      code += analyze_infos(document_root.elements[XRL_INFOS]) if document_root.elements[XRL_INFOS]
      
      code += analyze_loop(document_root.elements[XRL_LOOP], 0) if document_root.elements[XRL_LOOP]
      
      #code += "pdf.Output()"
      # code += "send_data pdf.output, :filename => hello_advance.pdf, :type => 'application/pdf'"
      
      code += "end" 
      # send_data module_eval(code), :filename => voila.pdf, :type => 'application/pdf' "
      module_eval(code)
    end
    
    # this function test if the balise info exists in the template and add it in the code	
    def analyze_infos(infos)
      # puts infos.is_a? String
      code = ''
      infos.each_element(XRL_INFO) do |info|
        case info.attributes['type']
          #   when "created-on"
          #    code += 'pdf.Set(\"#{info.text}\")'
        when "written-by"
          code += "pdf.set_author('#{info.text}')\n"
        when "created-by"
          code += "pdf.set_creator('#{info.text}')\n"
        end
      end
      code.to_s
    end

    # this function 	
    def analyze_loop(loop, depth)
      code = "c= ActiveRecord::Base.connection \n"
      if loop.attributes['query']
        code += "result = [] \n c.execute('"+ loop.attributes['query'] + "').each do |res| result << res end \n" 
      end  
      loop.each_element do |element|
        
        code += self.send('analyze_'+ element.name,element,depth+1) if [XRL_BLOCK, XRL_LOOP].include? element.name 
      end
      code.to_s
      
    end
    
    #     
    def analyze_block(block, depth)
      code = ''
      if block.attributes['type'] == 'header'
       code += "mode = :"+ (block.attributes['mode'] ? block.attributes['mode'] : 'all') + "\n" 
      end  
      block.each_element do |element|
        code += self.send('analyze_'+ element.name,element) if [XRL_TEXT].include? element.name 
      end
      code.to_s
    end 
    
    # 
    #def analyze_rule(rule)
     #code = ''
     #if block.attributes['type'] == 'header'
      # code += "mode = "+ (block.attributes['mode'] ? block.attributes['mode'] : 'all') 
       #block.each_element do |element|
        #  code += self.send('analyze_'+element.name,element)
       #end
    #end
   #end 
    
    #  
    def analyze_text(text)
     code = ''
     #if block.attributes['type'] == 'header'
      # code += "mode = "+ (block.attributes['mode'] ? block.attributes['mode'].to_s : 'all') 
       #block.each_element do |element|
        #  code += self.send('analyze_'+element.name,element)
       #end
    #end
      code.to_s
   end 
    
    # 
    #def analyze_image(image)
     #code = ''
     #if block.attributes['type'] == 'header'
      # code += "mode = "+ (block.attributes['mode'] ? block.attributes['mode'].to_s : 'all') 
       #block.each_element do |element|
        #  code += self.send('analyse_'+element.name,element)
       #end
    # end
   # end
    
   

  end

  # insertion of the module in the Actioncontroller
  ActionView::Base.send :include, PdfReport

  
end

module ActionView
  class Base
    # this function looks for a method render_report_template and calls analyse_template if not.
    def render_report(template, id)
      raise Exception.new "Your argument template must be a string" unless template.is_a? String
      digest = Digest::MD5.hexdigest(template)
      self.class.analyze_template(template, digest, id) unless self.methods.include? 'render_report_#{digest}'

      pdf = self.send('render_report_'+digest,id)
      
      
      
    end
  end
end




