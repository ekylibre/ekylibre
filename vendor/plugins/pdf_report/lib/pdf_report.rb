# This module groups the different methods allowing to obtain a PDF document.

module PdfReport



  
  def self.included (base)
    base.extend(ClassMethods)
  end

  module ClassMethods
    
    require 'rexml/document'
    include REXML
    require 'digest/md5'
    
      

    # this function begins to analyse the template extracting the main characteristics of
    # the Pdf document as the title, the orientation, the format, the unit ... 
    def analyze_template(template, name, id)
      document = Document.new(template)#File.new(template))
      document_root = document.root
      raise Exception.new "Only SQL" unless document_root.attributes['query-standard']||'sql' == 'sql'
      code = 'def render_report_'+name+'(id)'+"\n"
      
      code += 'pdf = FPDF.new("#{document_root.attributes[\'orientation\']}","#{document_root.attributes[\'unit\']}","#{document_root.attributes[\'format\']}", "#{document_root.attributes[\'size\']}")' + "\n end"
   
     # code += analyze_infos(template,document_root.elements['infos']) if document_root.elements['infos']
      
      #code += analyze_loop(template, root.elements['loop']) if root.elements['loop']
      # code += ' end;'
      #code += 'pdf.Close(); pdf.Output(); end'
      
      # ActionView::Base.logger.error(code)
      module_eval(code)
      # render_report_1
    end
    
    # this function test if the balise info exists in the template and add it in the code	
    def analyze_infos(template, infos)
      infos.each_element('info') do |info|
        case info.attributes['type']
        #when "created-on"
         # code += 'pdf.Set(\"#{info.text}\")'
        when "written-by"
          code += 'pdf.SetAuthor(\"#{info.text}\")'
        when "created-by"
          code += 'pdf.SetCreator(\"#{info.text}\")'
        end
        code
      end
      
    end

    

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



