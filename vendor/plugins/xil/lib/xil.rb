# plugin XIL : XML-based Impression-template Language
# This module groups the different methods allowing to obtain a PDF document by the analyze of a template.

module Ekylibre
  module Xil

    def self.included (base)
      base.extend(ClassMethods)
      
    end

    module ClassMethods
      
      require 'rexml/document'
      require 'digest/md5'
      require 'fpdf'
      
      include REXML
      
      # Array listing the main options used by XIL-plugin and specified here as a global variable.
      @@xil_options={:features=>[], :impressions_path=>"#{RAILS_ROOT}/private/impressions", :subdir_size=>4096, :impression_model_name=>:impressions, :template_model_name=>:templates, :company_variable=>:current_company}
   
      mattr_accessor :xil_options
      
      #List of constants to identify the balises.
      XIL_TEMPLATE='template'
      XIL_TITLE='title'
      XIL_LOOP='loop'
      XIL_INFOS='infos'
      XIL_INFO='info'
      XIL_BLOCK='block'
      XIL_TEXT='text'
      XIL_IMAGE='image'
      XIL_LINE='line'
      XIL_PAGEBREAK='page-break'
      XIL_RECTANGLE='rectangle'
      
      ORIENTATION={:portrait=>'P', :landscape=>'L'}
      
      # this function begins to analyze the template extracting the main characteristics of
      # the PDF document as the title, the orientation, the format, the unit ... 
      def analyze_template(template, options={})
        document=Document.new(template)
        document_root=document.root || (raise Exception.new("The template has not root."))
      
        raise Exception.new("Only SQL") unless document_root.attributes['query-standard']||'sql' == 'sql'
        
        options[:orientation]=(document_root.attributes['orientation'] || ORIENTATION.to_a[0][0]).to_sym
        
        raise Exception.new("Bad orientation in the template") unless ORIENTATION.include? options[:orientation]
        
        options[:unit]             = attribute(document_root, :unit, 'mm')
        options[:format]           = attribute(document_root, :format, 'A4')
        options['margin_top']      = attribute(document_root, 'margin-top', 5).to_f
        options['margin_bottom']   = attribute(document_root, 'margin-bottom', 5).to_f
        options[:block_y]          = 'b' # before_y.
        options[:remaining]        = 'a' # after_y.
        options[:available_height] = 'h' # height of the page available in the time.
        options[:page_number]      = 'n' # page_number.
        options[:count]            = 'm' # block_number in the current page.
        options[:pdf]              = 'p' # FPDF object.
        options[:now]              = 't' # timestamp NOW.
        options[:title]            = 'g' # title of the document.
        options[:storage]          = 's' # path of the document storage.
        options[:file]             = 'f' # file of the document sterage.
        options[:temp]             = XIL_TITLE # temporary variable.
        options[:key]              = 'k'
        options[:depth]            = -1 # depth of the different balises loop imbricated.
        options[:permissions]      = [:copy,:print]
        options[:file_name]        = 'o'  # file with the extension.
             
        # prototype of the generated function.
        code ="def render_xil_"+options[:name].to_s+"_"+options[:output].to_s+"("+options[:key]+")\n"
        
        code+=options[:now]+"=Time.now\n"
        code+=options[:title]+"='file'\n"
        

        # declaration of the PDF document and first options.
        code+=options[:pdf]+"=FPDF.new('"+ORIENTATION[options[:orientation]]+"','"+options[:unit]+"','" +options[:format]+ "')\n"
        #code+=options[:pdf]+".set_protection(["+options[:permissions].collect{|x| ':'+x.to_s}.join(",")+"],'')\n"
        code+=options[:pdf]+".alias_nb_pages('[PAGENB]')\n"
        code+=options[:available_height]+"="+(format_height(options[:format],options[:unit])-options['margin_top']-options['margin_bottom']).to_s+"\n"
        code+=options[:page_number]+"=1\n"
        code+=options[:count]+"=0\n"
        code+=options[:pdf]+".set_auto_page_break(false)\n"

        options[:specials]=[{}]
        options[:defaults]={"size"=>10, "family"=>'Arial', "color"=>'#000', "border-color"=>'#000', "border-width"=>0.2, "radius"=>0, "vertices"=>'1234'}.merge(document_root.attributes)

        code+=options[:pdf]+".set_font('"+options[:defaults]['family']+"','',"+options[:defaults]['size'].to_s+")\n"
        code+=options[:pdf]+".set_margins(0,0)\n"

        # add the first page.
        code+=options[:pdf]+".add_page()\n"
        code+=options[:block_y]+"="+options['margin_top'].to_s+"\n"
        code+=options[:remaining]+"="+options[:available_height]+"\n"
        code+="c=ActiveRecord::Base.connection\n"
        code+=analyze_title(document_root.elements[XIL_TITLE], options) if document_root.elements[XIL_TITLE]
        code+=analyze_infos(document_root.elements[XIL_INFOS],options) if document_root.elements[XIL_INFOS]
        code+=analyze_loop(document_root.elements[XIL_LOOP],options) if document_root.elements[XIL_LOOP]
        
        code+=options[:pdf]+"="+options[:pdf]+".Output()\n"
        code+=options[:file_name]+"="+options[:title]+".gsub(/[^a-z0-9\_]/i,'_')+'."+options[:output].to_s+"'\n"

        # if a storage of the PDF document is implied by the user.
        if @@xil_options[:features].include? :impression
          code+="binary_digest=Digest::SHA256.hexdigest("+options[:pdf]+")\n"
          code+="unless ::"+@@xil_options[:impression_model].to_s+".exists?(['template_md5 = ? AND key = ? AND sha256 = ?','"+options[:name]+"',"+options[:key]+",'+binary_digest+'])\n"
          code+="impression=::"+@@xil_options[:impression_model].to_s+".create!(:key=>"+options[:key]+",:template_md5=>'"+options[:md5]+"', :sha256=>binary_digest, :original_name=>"+options[:file_name]+", :printed_at=>(Time.now), :company_id=>@"+options[:current_company].to_s+".id,:filename=>'t')\n"
          code+="save_impression("+options[:pdf]+")\n"
 
         #code+=options[:storage]+"='"+@@xil_options[:impressions_path]+"/'+(impression.id/"+@@xil_options[:subdir_size].to_s+").to_i.to_s+'/'\n"
          #code+="Dir.mkdir("+options[:storage]+") unless File.directory?("+options[:storage]+")\n"
          
          # creation of file and storage of code in. 
         # code+=options[:file]+"=File.open("+options[:storage].to_s+"+impression.id.to_s,'wb')\n"
         # code+=options[:file]+".write("+options[:pdf]+")\n"
         # code+=options[:file]+".close()\n"
          
         # code+="impression.filename="+options[:storage]+"+impression.id.to_s\n"
         # code+="impression.save!\n"
          code+="end\n"
        end
                
        # displaying of the PDF document.
        code+="send_data "+options[:pdf]+", :filename=>"+options[:file_name]+"\n"
        code+="end\n" 
                       
        if RAILS_ENV=="development"
          f=File.open('/tmp/test.rb','wb')
          f.write(code)
          f.close()
        end

        module_eval(code)
      end
      
      # if the attribute of an element has a value. Otherwise, a default value is used.
      def attribute(element, attribute, default=nil)
        if default.nil?
          element.attributes[attribute.to_s]
        else
          element.attributes[attribute.to_s]||default 
        end
      end

      # the format height of the page computed as from the format specifying in the template.
      def format_height(format, unit)
        coefficient = FPDF.scale_factor(unit)
        FPDF.format(format,coefficient)[1].to_f/coefficient
      end
      
      # this function test if the balise info exists in the template and adds it in the code. Mainly informations
      # as title, author identity, date ... are saved.
      def analyze_infos(infos,options={})
        code=''
        infos.each_element(XIL_INFO) do |info|
          case info.attributes['type']
          when "subject-on"
            code+=options[:pdf]+".set_subject('#{info.text}')\n"
          when "written-by"
            code+=options[:pdf]+".set_author('#{info.text}')\n"
          when "created-by"
            code+=options[:pdf]+".set_creator('#{info.text}')\n"
          end
        end
        code.to_s
      end
      

      # this function test if the balise title exists in the template and adds it in the code.	
      def analyze_title(title,options={})
        code=''
        query=title.attributes['query']
        # if the title is created as from a query.
        if query=~/^SELECT\ [^;]*$/i
          result=options[:temp]
          options[:fields]={} if options[:fields].nil?
          query.split(/\ from\ /i)[0].to_s.split(/select\ /i)[1].to_s.split(',').each do |s|
            options[:fields][result+'.'+s.downcase.strip] = result+"[\""+s.downcase.strip+"\"].to_s" 
          end
          
          code+=result+"=c.select_one(\'"+clean_string(query, options,true)+"\')\n"
        end
        code+=options[:title]+"='"+clean_string(title.text,options)+"'\n"
        code.to_s
      end
      

      # this function runs the different elements loop in the template and analyzes each of it. 	
      def analyze_loop(loop, options={})
        options[:depth] += 1
        code=''
        attrs = loop.attributes
        
        # in the case where many elements loop are imbricated, a variable of depth is precised
        # to better save the results of query returned by each them.
        if options[:depth]>=1 
          options[:specials][options[:depth]]={}
          options[:specials][options[:depth]][:header]=(options[:specials][options[:depth]-1][:header]).dup
          options[:specials][options[:depth]][:footer]=(options[:specials][options[:depth]-1][:footer]).dup
        end
        
        raise Exception.new("You must specify a name beginning by a character for the element loop (2 characters minimum): "+attrs['name'].to_s) unless attrs['name'].to_s=~/^[a-z][a-z0-9]+$/
        result=attrs["name"]
        
        options[:fields]={} if options[:fields].nil?
        query=attrs['query']
        
        # if a query is present as an attribute in the balise loop then, the query is executed and the results saved.
        if query
          if query=~/^SELECT\ [^;]*$/i
            query.split(/\ from\ /i)[0].to_s.split(/select\ /i)[1].to_s.split(',').each do |s| 
              options[:fields][result+'.'+s.downcase.strip] = result+"[\""+s.downcase.strip+"\"].to_s"
            end
            code+="for "+result+" in c.select_all('"+clean_string(query,options,true)+"')\n" 
          else
            raise Exception.new("Invalid SQL query. Maybe there is an SQL injection.")
          end
        else
          code+=result+"=[]\n"
        end

        # begin to run the elements loop.
        loop.each_element do |element|
          depth=options[:depth]
          # verify if it is a header or a footer block and compute the parameters of the block
          # as the height ...
          if (element.attributes['type']=='header' or element.attributes['type']=='footer')
            mode=attribute(element, :mode, 'all').to_sym
            type=attribute(element, :type, 'header').to_sym
            options[:specials]=[] unless options[:specials].is_a? Array
            options[:specials][depth]={} unless options[:specials][depth].is_a? Hash
            options[:specials][depth][type]={} unless options[:specials][depth][type].is_a? Hash
            if mode==:all
              options[:specials][depth][type][:even] = element.dup
              options[:specials][depth][type][:odd]  = options[:specials][depth][type][:even]
            else
              options[:specials][depth][type][mode] = element.dup
            end
            
          else          
            # if a conditional attribute is precised for this element.
            unless element.attributes['if'].nil?
              condition=element.attributes['if']
              query = 'SELECT ('+condition+')::BOOLEAN AS x'
              code+="if c.select_one(\'"+clean_string(query, options,true)+"\')[\"x\"]==\"t\"\n"
            end
            
            # if the block considered is not a header or footer's block.
            if element.name==XIL_BLOCK
              block_height = block_height(element)
              bhfe = block_height(options[:specials][depth][:footer][:even])
              bhfo = block_height(options[:specials][depth][:footer][:odd])
              
              # if the height of the block is bigger than the remaining height of the page, a new
              # page is created and the appropriate header sets in.
              code+="if("+options[:block_y]+"=="+options['margin_top'].to_s+")\n"+analyze_header(options)+"end\n" unless options[:specials].empty?
              
              if bhfe==bhfo
                code+="if("+options[:count]+"==0 and "+options[:remaining]+"<"+(block_height+bhfe).to_s+")\nraise Exception.new('Footer too big')\n"
                code+="elsif("+options[:remaining]+"<"+(block_height+bhfe).to_s+")\n"
              else
                code+="if("+options[:count]+"==0 and "+options[:remaining]+"<"+block_height.to_s+"+"+bhfe.to_s+" and "+options[:remaining]+"<"+bhfo.to_s+")\nraise Exception.new('Footer too big')\n"
                code+="elsif("+options[:remaining]+"<"+block_height.to_s+"+("+options[:page_number]+".even? ? "+bhfe.to_s+":"+bhfo.to_s+"))\n"
              end
              code+=analyze_page_break(element,options)+"\n"
              code+="end\n"
              code+=options[:count]+"+=1\n"
            end
            code+=self.send('analyze_'+ element.name.gsub("-","_"),element, options.dup) if [XIL_LOOP, XIL_BLOCK, XIL_PAGEBREAK].include?(element.name)
            code+="end\n" unless element.attributes['if'].nil?
          end
          
        end
        # the footer block is settled in the last page of PDF document.
        code+=analyze_footer(options) if options[:depth]==0
        code+="end\n" if query
        code.to_s
      end
      
      # runs each blocks and analyzes them.    
      def analyze_block(block, options={})
        code=''
        block_height=block_height(block)
        
        # it runs
        #unless options[:format].split('x')[1].to_i >= block_height(block) and options[:format].split('x')[0].to_i >= block_width(block) 
        # raise Exception.new("Sorry, You have a block which bounds are incompatible with the format specified.")
        # puts block_width(block).to_s+"x"+block_height(block).to_s+":"+options[:format]
        #end
        
        # runs the elements of a block as text, image, line and rectangle.
        block.each_element do |element|
          attrs=element.attributes
          case element.name
          when 'line'
            code+=options[:pdf]+".set_xy("+attrs['x1']+","+options[:block_y]+"+"+attrs['y1']+")\n"
          else
            code+=options[:pdf]+".set_xy("+attrs['x']+","+options[:block_y]+"+"+attrs['y']+")\n"
          end
          code+=self.send('analyze_'+ element.name,element,options).to_s if [XIL_TEXT,XIL_IMAGE,XIL_LINE,XIL_RECTANGLE].include? element.name
        end
        code+=options[:block_y]+"+="+block_height.to_s+"\n"
        code+=options[:remaining]+"-="+block_height.to_s+"\n"
        code.to_s
      end 
      
      # computes the height of the considered block.
      def block_height(block)
        height=0
        block.each_element do |element|
          attrs=element.attributes
          case element.name
          when 'line'
            h=attrs['y1'].to_f>attrs['y2'].to_f ? attrs['y1'].to_f : attrs['y2'].to_f
          else
            h=attrs['y'].to_f+attrs['height'].to_f
          end
          height=h if h>height
        end
        h=block.attributes['height']||0
        return height>h ? height : h
      end 
      
      # computes the width of the considered block.
      def block_width(block)
        width=0
        block.each_element do |element|
          attrs=element.attributes
          case element.name
          when 'line'
            w=attrs['x1'].to_f>attrs['x2'].to_f ? attrs['x1'].to_f : attrs['x2'].to_f
          else
            w=attrs['x'].to_f+attrs['width'].to_f
          end
          width=w if w>width
        end
        w=block.attributes['width']||0
        return width>h ? width : w
      end 

      # a new page is created and added to the PDF document.
      def analyze_page_break(page_break,options={})
        code=""
        code+=analyze_footer(options)
        code+=options[:pdf]+".add_page()\n"
        code+=options[:count]+"=0\n"
        code+=options[:page_number]+"+=1\n"
        code+=options[:block_y]+"="+options['margin_top'].to_s+"\n"
        code+=options[:remaining]+"="+options[:available_height].to_s+"\n"
        code+=analyze_header(options)
        code.to_s
      end
      
      # runs and analyzes each header block in the template.
      def analyze_header(options={})
        code=""
        unless options[:specials].empty?
          unless options[:specials][options[:depth]].nil?
            unless options[:specials][options[:depth]][:header].nil?
              so=analyze_block(options[:specials][options[:depth]][:header][:odd],options)
              se=analyze_block(options[:specials][options[:depth]][:header][:even],options)
              if so!=se
                code+="if "+options[:page_number]+".even?\n"+se+"else\n"+so+"end\n"
              else
                code+=se
              end
            end
          end
        end
        code.to_s
      end
      
      # runs and analyzes each footer block in the template.
      def analyze_footer(options={})
        code=""
        unless options[:specials].empty?
          unless options[:specials][options[:depth]].nil?
            unless options[:specials][options[:depth]][:footer].nil?
              so=analyze_block(options[:specials][options[:depth]][:footer][:odd],options)
              se=analyze_block(options[:specials][options[:depth]][:footer][:even],options)
              if so!=se
                code+="if "+options[:page_number]+".even?\n"
                code+=options[:block_y]+"+="+options[:remaining]+"-"+block_height(options[:specials][options[:depth]][:footer][:even]).to_s+"\n"
                code+=se
                code+="else\n"
                code+=options[:block_y]+"+="+options[:remaining]+"-"+block_height(options[:specials][options[:depth]][:footer][:odd]).to_s+"\n"
                code+=so
                code+="end\n"
              else
                code+=options[:block_y]+"+="+options[:remaining]+"-"+block_height(options[:specials][options[:depth]][:footer][:odd]).to_s+"\n"
                code+=se
              end
            end
          end
        end
        code.to_s
      end
      
      
      # runs and analyzes each text element in the template with specific attributes as color, font, family...
      def analyze_text(text, options={})
        code=''
        attrs=text.attributes
        #raise Exception.new("Your text is out of the block") unless attrs['y'].to_i < attrs['width'].to_i
        color=attrs['color']||options[:defaults]['color']
        family=attrs['family']||options[:defaults]['family']
        size=attrs['size']||options[:defaults]['size']
        if attrs['border-color'] or attrs['border-width'] or attrs['background-color']
          code+=analyze_rectangle(text,options)
        end
        style=''
        style+='B' if attrs['weight']=='bold'
        style+='U' if attrs['decoration']=='underline'
        style+='I' if attrs['style']=='italic'
        code+=options[:pdf]+".set_text_color("+color_to_rvb(color)+")\n"
        code+=options[:pdf]+".set_font('"+family+"','"+style+"',"+size.to_s+")\n" 
        code+=options[:pdf]+".cell("+attrs['width']+","+attrs['height']+",'"+
          clean_string(text.text.to_s, options)+"',0,0,'"+attrs['align']+"',false)\n"
        code.to_s
      end 
      
      # runs and analyzes each image element in the template with specific attributes as width, height.
      def analyze_image(image,options={})
        code=''
        attrs=image.attributes
        code+=options[:pdf]+".image('"+attrs['src']+"',"+attrs['x']+","+options[:block_y]+"+"+attrs['y']+","+attrs['width']+","+attrs['height']+")\n"   
        code.to_s
      end

      # runs and analyzes each line element in the template.
      def analyze_line(line,options={})   
        code=''
        attrs=line.attributes
        border_color=attrs['border-color']||options[:defaults]['border-color']
        border_width=attrs['border-width']||options[:defaults]['border-width']
        code+=options[:pdf]+".set_draw_color("+color_to_rvb(border_color)+")\n"
        code+=options[:pdf]+".set_line_width("+border_width.to_s+")\n"
        code+=options[:pdf]+".line("+attrs['x1']+","+options[:block_y]+"+"+attrs['y1']+","+
          attrs['x2']+","+options[:block_y]+"+"+attrs['y2']+")\n"
        code.to_s
      end 
      
      # runs and analyzes each rectangle element in the template.
      def analyze_rectangle(rectangle,options={})
        code=''
        attrs=rectangle.attributes 
        radius=attribute(rectangle,'radius',options[:defaults]['radius'])
        vertices=attribute(rectangle,'vertices',options[:defaults]['vertices'])
        style=''
        if attrs['background-color']
          code+=options[:pdf]+".set_fill_color("+color_to_rvb(attrs['background-color'])+")\n"
          style+='F'
        end
        if attrs['background-color'].nil? or attrs['border-color'] or attrs['border-width']
          border_color=attrs['border-color']||options[:defaults]['border-color']
          border_width=attrs['border-width']||options[:defaults]['border-width']
          code+=options[:pdf]+".set_line_width("+border_width.to_s+")\n" 
          code+=options[:pdf]+".set_draw_color("+color_to_rvb(border_color)+")\n"
          style+='D'
        end
        code+=options[:pdf]+".rectangle("+attrs['x']+","+options[:block_y]+"+"+attrs['y']+
          ","+attrs['width']+","+attrs['height']+","+radius.to_s+",'"+style+"','"+vertices+"')\n"
        code.to_s
      end
      
      # converts the color attribute of an element in a better easier format to understand by the plugin.
      def color_to_rvb(color)
        color="#"+color[1..1]*2+color[2..2]*2+color[3..3]*2 if color=~/^\#[a-f0-9]{3}$/i
        if color=~/^\#[a-f0-9]{6}$/i
          color[1..2].to_i(16).to_s+","+color[3..4].to_i(16).to_s+","+color[5..6].to_i(16).to_s  
        else
          '255,0,255' 
        end
      end
      
      # cleans the string removing superfluous characters and replacing certains constants.
      def clean_string(string,options,query=false)
        string.gsub!("'","\\\\'")
        options[:fields] = {} if options[:fields].nil?
        if query
          options[:fields].each{|f| string.gsub!("\#{"+f[0]+"}","\\\\'\'+"+f[1]+"+\'\\\\'")}
        else
          options[:fields].each{|f| string.gsub!("\#{"+f[0]+"}","\'+"+f[1]+"+\'")}
        end
        while (string=~/[^\#]\{[A-Z\_].*.\}/)
          str=string.split('{')[1].split('}')[0]
          if str=~/CURRENT_DATE.*/ or str=~/CURRENT_TIMESTAMP.*/
            if (str.match ':').nil?
              format="%Y-%m-%d"
              format+=" %H:%M" if str=="CURRENT_TIMESTAMP"
            else
              format=str.split(':')[1]
            end
            string.gsub!("{"+str+"}",'\'+'+options[:now]+'.strftime(\''+format+'\')+\' ')
          elsif str=~/KEY/
            string.gsub!("{"+str+"}",'\'+'+options[:key]+'.to_s+\'')
          elsif str=~/TITLE/
            string.gsub!("{"+str+"}",'\'+'+options[:title]+'.to_s+\'')
          elsif str=~/PAGENO/
            string.gsub!("{"+str+"}",'\'+'+options[:page_number]+'.to_s+\'')
          elsif str=~/PAGENB/
            string.gsub!("{"+str+"}",'[PAGENB]')
            
          end
        end
        # the string is converted to the format ISO, which is more efficient for the PDF softwares to read the 
        # superfluous characters.
        Iconv.iconv('ISO-8859-15','UTF-8',string).to_s
      end 
    end
  end
end

# insertion of the module in the Actioncontroller
ActionController::Base.send :include, Ekylibre::Xil

module ActionController
  class Base
    
    # this function looks for a method render_xil_name _'output' and calls analyse_template if not.
    def render_xil(xil, options={}) 
      xil_options=Ekylibre::Xil::ClassMethods::xil_options
      options = {:output=>:pdf}.merge(options)

      template_options={:output=>options[:output]}
      template = nil
      # if the parameter is an integer.
      if xil.is_a? Integer
        template=xil_options[:template_model].find_by_id(xil)
        raise Exception.new('This ID has not been found in the database.') if template.nil?
        name=template.id.to_s  
        md5=template.md5
        template=template.content        
        # if the parameter is a string.
      elsif xil.is_a? String
        # it is a file with the XML extension. Else, an error is generated. 
        if File.file? xil 
          f=File.open(xil,'rb')
          xil=f.read.to_s
          f.close()
        end
        # the string begins by the XML standard format.
        if xil.start_with? '<?xml'
          template=xil
        else
          raise Exception.new("It is not an XML data.")
        end
        # encodage of string into a crypt MD5 format to easier the authentification of template by the XIL-plugin.
        md5=Digest::MD5.hexdigest(xil)
        name=md5      
        # the parameter is a template.  
      elsif xil_options[:features].include? :template
        if xil.is_a? xil_options[:template_model]
          template=xil.content 
          md5=xil.md5
          name=xil.id.to_s        
        end
      end  

      raise Exception.new("Type error on the parameter xil: "+xil.class.to_s) if template.nil?
      template_options[:md5]=md5
      template_options[:name]=name
      
      # tests if the variable current_company is available.
      if xil_options[:features].include? :template  or xil_options[:features].include? :impression
        current_company = instance_variable_get("@"+xil_options[:company_variable].to_s)
        raise Exception.new("No current_company.") if current_company.nil? 
        template_options[:current_company]=xil_options[:company_variable]
      end

      method_name="render_xil_"+name+"_"+options[:output].to_s

      #the function which creates the PDF function is executed here.
      self.class.analyze_template(template, template_options) unless self.methods.include? method_name 

      # Finally, the generated function is executed.
      self.send(method_name,options[:key])
    end



    # this function initializes the whole necessary environment for Xil. 
    def self.xil(options={})
      # runs all the name parameters passed to initialization and generate an error if it is undefined.
      options.each_key do |parameter|
        raise Exception.new("Unknown parameter : #{parameter}") unless Ekylibre::Xil::ClassMethods::xil_options.include? parameter
      end

      # Generate an exception if company_variable is  initialized and with another value of current_company.
      unless options[:company_variable].nil?
        raise Exception.new("Company_variable must be equal to current_company.") unless options[:company_variable].to_s.eql? "current_company"
      end
      
      xil_options=Ekylibre::Xil::ClassMethods::xil_options.merge(options)
      new_options=xil_options
      
      # some verifications about the different arguments passed to the init function during the XIL-plugin initialisation. 
      raise Exception.new("Parameter subdir_size must be an integer.") unless new_options[:subdir_size].is_a? Integer
      raise Exception.new("Parameter impressions_path must be a string.") unless new_options[:impressions_path].is_a? String
      raise Exception.new("Parameter features must be an array with maximaly two symbols.") unless new_options[:features].is_a? Array and new_options[:features].length<=2
      
      new_options[:features].detect do |element|
        unless element.is_a? Symbol
          raise Exception.new("The parameter features must be an array fulled with symbols.")
        end
      end

      # if a store of datas is implied by the user.
      if new_options[:features].include? :impression
        if new_options[:impression_model_name].is_a? Symbol
          new_options[:impression_model]=new_options[:impression_model_name].to_s.classify.constantize 
          
          # the model of impression specified by the user must contain particular fields.
         if ActiveRecord::Base.connection.tables.include? new_options[:impression_model].table_name 
           ["id", "filename","original_name","template_md5","sha256","rijndael","company_id"].detect do |field|
              raise Exception.new("The table of impression #{new_options[:impression_model]} must contain at least the following field: "+field) unless new_options[:impression_model].column_names.include? field
            end   
           
           # if the impression of the PDF documents is required, the function of saving impression is generated.
           # it allows to encode the PDF document (considered as a data block) with a specific key randomly created and 
           # which is returned. The encryption algorithm used is Rijndael.
           code+="require 'crypt/rijndael'\n"
           code+="def save_impression(block,options={})\n"
           code+="key='-'*32\n"
           code+="key=32.times do |index|\n"
           code+="key[index]=rand(256) end\n"
           code+="rijndael = Crypt::Rijndael.new('key')\n"
           code+="encrypted_block = rijndael.encrypt_block(block)\n"
           code+="impression=::options[:impression_model].to_s.find(:all,:conditions=>['template_md5 = ? AND key = ? AND sha256 = ?','options[:name]',options[:key],'binary_digest'])\n"
           code+="impression.rijndael='key'\n"
           code+="options[:storage]='options[:impressions_path]/(+impression.id+/options[:subdir_size].to_s).to_i.to_s/'\n"
           code+="Dir.mkdir(options[:storage]) unless File.directory?(options[:storage])\n"
           code+="options[:file]=File.open(options[:storage].to_s+encrypted_block.to_s,'wb')\n"
           code+="options[:file].write(options[:pdf])\n"
           code+="options[:file].close()\n"
           
           code+="impression.filename=options[:storage]+encrypted_block.to_s\n"
           code+="impression.save!\n"
          
           code+="end\n"
           
         end
        else
          raise Exception.new("The name of impression #{new_options[:impression_model_name]} is not a symbol.")
        end
        
        # if the folder does not exist, an error is generated.
        unless File.directory?(new_options[:impressions_path])
         raise Exception.new("Folder impressions does not exist.")
       end
      end  
      
      # if the user wishes to load a model to make the impression (facture). 
      if new_options[:features].include? :template
        if new_options[:template_model_name].is_a? Symbol
          new_options[:template_model]=new_options[:template_model_name].to_s.classify.constantize 
         
          # the model of template specified by the user must contain particular fields.
          if ActiveRecord::Base.connection.tables.include? new_options[:template_model].table_name
            ["id", "content","cache","company_id"].detect do |field|
              raise Exception.new("The table of template #{new_options[:template_model]} must contain at least the following field: "+field) unless new_options[:template_model].column_names.include? field
              end
          end
        else
          raise Exception.new("The name of template #{new_options[:template_model_name]} does not a symbol.")
        end
      end  

      Ekylibre::Xil::ClassMethods::xil_options=new_options
    end
 

   

 end
end






