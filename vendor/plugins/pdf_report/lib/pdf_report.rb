
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
      document=Document.new(template)
      document_root=document.root
      va_r='mm'
      depth=0
      raise Exception.new("Only SQL") unless document_root.attributes['query-standard']||'sql' == 'sql'   
      code='def render_report_'+name+'(id)'+"\n"
      
      raise Exception.new("Bad orientation in the template") unless document_root.attributes['orientation'] || 'portrait' == 'portrait'
      
      pdf='pdf'
      
      code+="orientation="+document_root.attributes['orientation']+"\n"
      code+=pdf+"=FPDF.new('P','"+ document_root.attributes['unit']+"','" + document_root.attributes['format']+ "')\n"
      code+=height_page(document_root)
      code+=pdf+".set_font('Arial','B',14)\n"
      code+=pdf+".add_page('orientation')\n"
      
      code+="y_block=15\n"
      code+=analyze_infos(document_root.elements[XRL_INFOS],pdf) if document_root.elements[XRL_INFOS]
      
      
      code+="c= ActiveRecord::Base.connection \n"+analyze_loop(document_root.elements[XRL_LOOP],pdf,depth) if document_root.elements[XRL_LOOP]     
      code+=pdf+".Output() \n"

      
      code+="end" 

      module_eval(code)
      code
    end
    
    #
     def height_page(template)
       code=''
       template=template.attributes
       coefficient = FPDF.scale_factor(template['unit'])
       code+="height_page="+FPDF.format(template['format'],coefficient)[1]+"\n"
       code.to_s
     end

    # this function test if the balise info exists in the template and add it in the code	
    def analyze_infos(infos,pdf)
      code=''
      infos.each_element(XRL_INFO) do |info|
        case info.attributes['type']
          #   when "created-on"
          #    code += 'pdf.Set(\"#{info.text}\")'
        when "written-by"
          code+=pdf+".set_author('#{info.text}')\n"
        when "created-by"
          code+=pdf+".set_creator('#{info.text}')\n"
        end
      end
      code.to_s
    end
    
    # this function 	
    #def analyze_loop(loop, *params)
    def analyze_loop(loop,pdf, depth, fields=nil, result=nil)
      code=''
      result="r"+depth.to_s
            
      query=loop.attributes['query']
      
      fields.each do |f| query.gsub!("\#{"+f[0]+"}","\\\\'\'+"+f[1]+"+\'\\\\'") end unless fields.nil?
      #array_gsub(fields, query)
      if query
        unless (query=~/^SELECT.*.FROM/).nil?
          fields={}
          query.split(/\ from\ /i)[0].to_s.split(/select\ /i)[1].to_s.split(',').each{|s| fields[s.downcase.strip]=result+"[\""+s.downcase.strip+"\"].to_s"}
          code+="for "+ result+" in c.select_all('"+query+"')\n" 
        end
      else
        code+="result=[]\n"
      end  
      loop.each_element do |element|
        code+=self.send('analyze_'+ element.name,element,pdf,depth+1,fields, result) if [XRL_BLOCK, XRL_LOOP].include? element.name 
        
      end
      
      code+="end \n" if query
      code.to_s
      
    end
    
    #def array_gsub(search=[],dest)
    #search.each do |f| dest.gsub!("\#{"+f[0]+"}","\\\\'\'+"+f[1]+"+\'\\\\'") end unless search.nil?
    #end 

    #     
    # def analyze_block(block, *params)
    def analyze_block(block,pdf, depth,fields=nil, result=nil)
      code=''
      width_block_depth=0 
      heigth_block_depth=0
      code+="height_block="+height_block(block).to_s+"\n"
      code+="if(height_page < height_block)\n"+pdf+".add_page('orientation')\n else \n height_page-=height_block\n end\n"
      #condition = block.attributes['if'] ? block.attributes['if']:''
      #unless condition.empty?
      # if condition=~('*.#{.*.}.*')
      
      #end
      
      if block.attributes['type']=='header'
        code+="mode = :"+ (block.attributes['mode'] ? block.attributes['mode'] : 'all') + "\n" 
      end 
      block.each_element do |element|
        attr_element=element.attributes
        code+=pdf+".set_xy(x_block+"+attr_element['x']+",y_block+"+attr_element['y']+")\n"
        code+=self.send('analyze_'+ element.name,element,pdf, depth, fields, result).to_s if [XRL_TEXT,XRL_IMAGE,XRL_RULE].include? element.name       
        
      end
      code+="y_block+=height_block\n"
      code.to_s
    end 
    
    #
    def height_block(block)
#      code=''
      height=0
      block.each_element do |element|
        h2=element.attributes['y'].to_i+element.attributes['height'].to_i
        height=h2 if h2>height
      end
    return height 
    end 
    
    # 
    #def analyze_rule(rule,*params)   
    def analyze_rule(rule,pdf,depth,fields=nil,result=nil)   
      code=''
      rule=rule.attributes
      right_border=rule['x'].to_i+ rule['width'].to_i
      bottom_border=rule['y'].to_i+rule['height'].to_i
      
      code+=pdf+".line("+rule['x']+","+rule['y']+","+right_border.to_s+","+bottom_border.to_s+") \n"
      
      code.to_s
      #end
    end 
    
    #  
    #def analyze_text(text, *params)
    def analyze_text(text,pdf, depth, fields=nil, result=nil)
      code = ''
      raise Exception.new("Your text is out of the block") unless text.attributes['y'].to_i < text.attributes['width'].to_i
      
      data = text.text.gsub("'","\\\\'")
      text=text.attributes
      
      fields .each do |f| data.gsub!("\#{"+f[0]+"}","\'+"+f[1]+"+\'")end unless fields.nil?  
      #array_gsub(fields, data)  
      code+=pdf+".set_text_color("+color_element(text,color)+")\n" unless text.attributes['color'].nil?
      
      code+=pdf+".cell("+text['width']+","+text['height']+",'"+data+"',0,0,'"+text['align']+"')\n"
      
      code.to_s
      
    end 
    
    # 
    #def analyze_image(image,*params)
    def analyze_image(image,pdf,depth, fields=nil, result=nil)
      code = ''
      image = image.attributes
      code += pdf+".image('"+image['src']+"',"+image['x']+","+image['y']+","+image['width']+","+image['height']+")\n"   
      code.to_s
    end
    
    #
    def analyze_rectangle(rectangle,pdf,depth,fields=nil,result=nil)
      code=''
      rectangle=rectangle.attributes
      code+=pdf+".set_line_width("+rectangle['border_width']+")\n" unless rectangle['border-width'].nil?    
      code+=pdf+".set_draw_color("+color_element(rectangle,border-color)+")\n" unless rectangle['border-color'].nil?
      code+=pdf+".set_fill_color("+color_element(rectangle,background-color)+")\n" unless rectangle['background-color'].nil?
      code+=pdf+".rect("+rectangle['x']+","+rectangle['y']+","+rectangle['width']+","+rectangle['heigth']+","+rectangle['style']+")\n"
      code.to_s
    end
    
    #
    def color_element(element, attribute)
      color_table=(element[attribute]).split('#')[1].split('')
      return(color_table[0].to_i*16)+","+(color_table[1].to_i*16)+","+(color_table[2].to_i*16)  
    end

  end
  
  
end

# insertion of the module in the Actioncontroller
ActionController::Base.send :include, PdfReport


module ActionController
  class Base
    # this function looks for a method render_report_template and calls analyse_template if not.
    def render_report(template, id)
      raise Exception.new("Your argument template must be a string") unless template.is_a? String
      digest = Digest::MD5.hexdigest(template)
      code = self.class.analyze_template(template, digest, id) unless self.methods.include? 'render_report_#{digest}'
      puts code

      pdf = self.send('render_report_'+digest,id)
      
      
      # code
    end
  end
end




