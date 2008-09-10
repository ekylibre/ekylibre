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
      

    # this function begins to analyse the template extracting the main characteristics of
    # the Pdf document as the title, the orientation, the format, the unit ... 
    def analyze_template(template, name, id)
      document = Document.new(template)
      document_root = document.root
      va_r = 'mm'
      raise Exception.new "Only SQL" unless document_root.attributes['query-standard']||'sql' == 'sql'   
      code = 'def render_report_'+name+'(id)'+"\n"
       
      raise Exception.new "Bad orientation in the template" unless document_root.attributes['orientation'] || 'portrait' == 'portrait'
      
      pdf='pdf'
      
      code += pdf+"=FPDF.new('P','"+ document_root.attributes['unit']+"','" + document_root.attributes['format']+ "')\n"
     
      code += analyze_infos(template, document_root.elements['infos']) if document_root.elements['infos']
     
      code += analyze_loop(template, document_root.elements['loop']) unless document_root.elements['loop']
     
      #code += "pdf.Output()"
     # code += "send_data pdf.output, :filename => hello_advance.pdf, :type => 'application/pdf'"
     
      code += "end" 
     # send_data module_eval(code), :filename => voila.pdf, :type => 'application/pdf' "
     module_eval(code)
    end
    
    # this function test if the balise info exists in the template and add it in the code	
    def analyze_infos(template, infos)
      # puts infos.is_a? String
      code = ''
      infos.each_element("info") do |info|
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
    def analyze_loop(template, loop)
      code = ''
      if loop.attributes['query']
        code = "result = [] \n ActiveRecord::Base.connection.execute('"+ loop.attributes['query'] + "').each do |res| result << res end \n"  
      loop.each_recursive('block' || 'loop') do |element|
          code += analyse_#{element}(template, element)
 
      end
     code.to_s
    end
   
    
   #def analyze_block(template, block)
    # code = ''
    # if block.attributes['type'] == 'header'
      #   code = "mode = "+ (block.attributes['mode'] ? block.attributes['mode']         # .to_s:'all') 
     #block.each_element do |element|
      #   code += analyse_#{element}(template, )
       #code += analyse_text(template, )
       #code += analyse_image(template,)
       #code += analyse_rule(template,)
       #  end
   #end
   
   


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



