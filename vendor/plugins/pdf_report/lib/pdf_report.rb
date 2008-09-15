
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
    
    #List of constants for identify the balises
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
      code += pdf+".set_font('Arial','B',14)\n"
      code += pdf+".add_page\n"
      
      code += analyze_infos(document_root.elements[XRL_INFOS]) if document_root.elements[XRL_INFOS]
      
#      code += "c= ActiveRecord::Base.connection \n"+analyze_loop(document_root.elements[XRL_LOOP], :depth => 0, :fields => "nil") if document_root.elements[XRL_LOOP]
 
      code += "c= ActiveRecord::Base.connection \n"+analyze_loop(document_root.elements[XRL_LOOP], 0) if document_root.elements[XRL_LOOP]     
      code += "pdf.Output() \n"
      # code += "send_data pdf.output, :filename => hello_advance.pdf, :type => 'application/pdf'"
      
      code += "end" 
      # send_data module_eval(code), :filename => voila.pdf, :type => 'application/pdf' "
      module_eval(code)
      code
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
    #def analyze_loop(loop, *params)
    def analyze_loop(loop, depth, fields=nil, result=nil)
      #code = "puts "+depth.to_s+ "\n"
      result = "r"+depth.to_s
      #fields = ''
      query = loop.attributes['query']
      fields.each do |f| query.gsub!("\#{"+f[0]+"}","\\\\'\'+"+f[1]+"+\'\\\\'") end unless fields.nil?
      #array_gsub(fields, query)
      if query
        unless (query=~/^SELECT.*.FROM/).nil?
          fields = {}
          query.split(/\ from\ /i)[0].to_s.split(/select\ /i)[1].to_s.split(',').each{|s| fields[s.downcase.strip]=result+"[\""+s.downcase.strip+"\"].to_s"}
          code += "for "+ result+" in c.select_all('"+query+"')\n" 
          
        end
      else
        code +=result+"=[]\n"
      end  
      loop.each_element do |element|
       code += self.send('analyze_'+ element.name,element,depth+1,fields, result) if [XRL_BLOCK, XRL_LOOP].include? element.name 
       # code += self.send('analyze_'+ element.name,element,:depth => params[:depth]+1,:fields => fields, :result => result) if [XRL_BLOCK, XRL_LOOP].include? element.name 
          end
     
      code += "end \n" if query
      code.to_s
      
    end
    
    #def array_gsub(search=[],dest)
     #search.each do |f| dest.gsub!("\#{"+f[0]+"}","\\\\'\'+"+f[1]+"+\'\\\\'") end unless search.nil?
    #end 

   #     
   # def analyze_block(block, *params)
   def analyze_block(block, depth,fields=nil, result=nil)
      code=''
      width_block_depth = 0 
      heigth_block_depth = 0 
      #condition = block.attributes['if'] ? block.attributes['if']:''
      #unless condition.empty?
       # if condition=~('*.#{.*.}.*')

      #end
      #code = "puts "+depth.to_s+ "\n"
      if block.attributes['type'] == 'header'
       code += "mode = :"+ (block.attributes['mode'] ? block.attributes['mode'] : 'all') + "\n" 
      end 
      block.each_element do |element|
        width_block_depth += element.attributes['width'].to_i 
        heigth_block_depth += element.attributes['height'].to_i 
      end
      block.each_element do |element|
         #width_block_depth += element.attributes['width'] 
       # code += self.send('analyze_'+ element.name,element, :depth => params[:depth], :fileds => params[:fields], :result => params[:result]).to_s if [XRL_TEXT, XRL_IMAGE].include? element.name 
       code += self.send('analyze_'+ element.name,element, depth, fields, result).to_s if [XRL_TEXT,XRL_IMAGE,XRL_RULE].include? element.name       # code += self.send('analyze_'+ element.name,element, depth, fields, result).to_s if [XRL_IMAGE].include? element.name 
       # code += self.send('analyse_'+ element.name)
      end
      code.to_s
    end 
    
    # 
    #def analyze_rule(rule,*params)   
    def analyze_rule(rule,depth,fields=nil,result=nil)   
      rule=rule.attributes
      right_border=rule['x'].to_i+ rule['width'].to_i
      bottom_border=rule['y'].to_i+rule['height'].to_i
      
      code = ''
      code += "pdf.line("+rule['x']+","+rule['y']+","+right_border.to_s+","+bottom_border.to_s+") \n"
      
    code.to_s
    #end
   end 
    
    #  
    #def analyze_text(text, *params)
    def analyze_text(text, depth, fields=nil, result=nil)
      code = ''
      raise Exception.new("Your text is out of the block") unless text.attributes['y'].to_i < text.attributes['width'].to_i
         
      data = text.text.gsub("'","\\\\'")
      text = text.attributes
      #puts text['x']
      fields .each do |f| data.gsub!("\#{"+f[0]+"}","\'+"+f[1]+"+\'")end unless fields.nil?  
      #array_gsub(fields, data)  
      code += "pdf.set_xy("+text['x']+","+text['y']+") \n"
      code += "pdf.cell("+text['width']+","+text['height']+",'"+data+"',0,0,'"+text['align']+"')\n"

      code.to_s

   end 
    
    # 
    #def analyze_image(image,*params)
    def analyze_image(image,depth, fields=nil, result=nil)
      code = ''
      image = image.attributes
      code += "pdf.image('"+image['src']+"',"+image['x']+","+image['y']+","+image['width']+","+image['height']+")\n"   
      code.to_s
    end
    
   

  end


  
end

# insertion of the module in the Actioncontroller
ActionController::Base.send :include, PdfReport


module ActionController
  class Base
    # this function looks for a method render_report_template and calls analyse_template if not.
    def render_report(template, id)
      raise Exception.new "Your argument template must be a string" unless template.is_a? String
      digest = Digest::MD5.hexdigest(template)
      code = self.class.analyze_template(template, digest, id) unless self.methods.include? 'render_report_#{digest}'
      puts code

      pdf = self.send('render_report_'+digest,id)
      
      
     # code
    end
  end
end




