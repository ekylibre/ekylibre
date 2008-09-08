# This module groups the different methods allowing to obtain a PDF document.

module PdfReport


  
  def self.included (base)
    base.extend(ClassMethods)
  end

  module ClassMethods



    # this function looks for a method render_report_template and calls analyse_template if not.
    def render_report(template, id)
      begin
        template = Template.find(template) if template.is_a? Integer or template.is_a? Template  
      rescue		
        raise ArgumentTypeError, "the template has not been found in the database, you must create before."    
      end		
      analyze_template(template) unless ActionController::Base.methods.include? 'render_report_#{template.id}'   	
      pdf = self.send('render_report_#{template.id}',id)
    end

    # this function 
    def analyze_template(template)
      doc = Document.new(File.new("#{template.name}"))
      root = doc.root
      template = root.elements['template']						 	
      if template.attributes['query-standard'] =~ 'sql'	
        code = 'def render_report_\'#{template.id}\'' + 'pdf = FPDF.new (\"#{template.attributes[\'orientation\']}\",\" 		    	      #{template.attributes[\'unit\']}\", \"#{template.attributes[\'format\']}\") + pdf.SetSubject(template.attributes[\'title\'])'
        
        code += analyze_infos(template, root.elements['infos']) if root.elements['infos']
	

        code += 'pdf.Close(); pdf.Output(); end'
        
      elsif
        raise	'You must specify sql for query-standard.'
      end
      

      
      
      
      
      ActionController::Base.logger.error(code)
      module_eval(code)
    end

    # this function test if the balise info exist in the template and add it in the code	
    def analyze_infos(template, infos)
      infos.each_element('info') do |info|
        case info.attributes['type']
        when "created-on"
          code += 'pdf.Set(\"#{info.text}\")'
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
  ActionController::Base.send :include, PdfReport

        
end





