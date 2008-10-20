# plugin XIL : XML-based Impression-template Language
# This module groups the different methods allowing to obtain a PDF document by the analyse of a template.

module Ekylibre
  module Xil

    def self.included (base)
      base.extend(ClassMethods)
      
    end

    module ClassMethods
      
      require 'rexml/document'
      require 'digest/md5'
      require 'fpdf'
      
      # library necessary for manipulate XML files.
      include REXML
      
      # array listing the main options used by Xil-plugin and specified here as a global variable.
      @@xil_options={:features=>[], :impressions_path=>"#{RAILS_ROOT}/private/impressions", :subdir_size=>4096, :impression_model_name=>:impressions, :template_model_name=>:templates}
   
      mattr_accessor :xil_options
      
      #List of constants for identify the balises
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
      
      # this function begins to analyse the template extracting the main characteristics of
      # the PDF document as the title, the orientation, the format, the unit ... 
      def analyze_template(template, options={})
        document=Document.new(template)
        document_root=document.root || (raise Exception.new("The template has not root."))
      
        raise Exception.new("Only SQL") unless document_root.attributes['query-standard']||'sql' == 'sql'
        
        options[:orientation] = (document_root.attributes['orientation'] || ORIENTATION.to_a[0][0]).to_sym
        
        raise Exception.new("Bad orientation in the template") unless ORIENTATION.include? options[:orientation]
        
        options[:unit]             = attribute(document_root, :unit, 'mm')
        options[:format]           = attribute(document_root, :format, 'A4')
        options['margin_top']      = attribute(document_root, 'margin-top', 5).to_f
        options['margin_bottom']   = attribute(document_root, 'margin-bottom', 5).to_f
        options[:block_y]          = 'b' # before_y
        options[:remaining]        = 'a' # after_y
        options[:available_height] = 'h' # height of page at a moment time
        options[:page_number]      = 'n' # page_number
        options[:count]            = 'm' # block_number in the current page
        options[:pdf]              = 'p' # FPDF object
        options[:now]              = 't' # timestamp NOW
        options[:title]            = 'l' # title of the document
        options[:storage]          = 's' # path of the document storage
        options[:file]             = 'f' # file of the document sterage
        options[:temp]             = XIL_TITLE # temporary variable
        options[:key]              = 'k'
        options[:depth]            = -1
        options[:permissions]      = [:copy,:print]
       
        # prototype of the generated function according to if a table of template is used or not.
        if @@xil_options[:features].include? :template
          code ="def render_xil_"+options[:template_id].to_s 
        else
          code ="def render_xil_"+options[:name].to_s 
        end
        code+="_"+options[:output].to_s+"("+options[:key]+")\n"
        
        code+=options[:now]+"=Time.now\n"

        # creation of the PDF document.
        code+=options[:pdf]+"=FPDF.new('"+ORIENTATION[options[:orientation]]+"','"+options[:unit]+"','" +options[:format]+ "')\n"
        # protection settings for the PDF document.
        code+=options[:pdf]+".set_protection(["+options[:permissions].collect{|x| ':'+x.to_s}.join(",")+"],'')\n"
        # first options.
        code+=options[:pdf]+".alias_nb_pages('[PAGENB]')\n"
        code+=options[:available_height]+"="+(format_height(options[:format],options[:unit])-options['margin_top']-options['margin_bottom']).to_s+"\n"
        code+=options[:page_number]+"=1\n"
        code+=options[:count]+"=0\n"
        code+=options[:pdf]+".set_auto_page_break(false)\n"

        options[:specials]      = [{}]
        options[:defaults]      = {"size"=>10, "family"=>'Arial', "color"=>'#000', "border-color"=>'#000', "border-width"=>0.2, "radius"=>0, "vertices"=>'1234'}.merge(document_root.attributes)

        code+=options[:pdf]+".set_font('"+options[:defaults]['family']+"','',"+options[:defaults]['size'].to_s+")\n"
        code+=options[:pdf]+".set_margins(0,0)\n"
        
        # creation of the first page of the document.
        code+=options[:pdf]+".add_page()\n"

        code+=options[:block_y]+"="+options['margin_top'].to_s+"\n"
        code+=options[:remaining]+"="+options[:available_height]+"\n"
        code+="c=ActiveRecord::Base.connection\n"
        
        # course of the XML file for ensure the settings of the PDF elements. 
        code+=analyze_title(document_root.elements[XIL_TITLE], options) if document_root.elements[XIL_TITLE]
        code+=analyze_infos(document_root.elements[XIL_INFOS],options) if document_root.elements[XIL_INFOS]
        code+=analyze_loop(document_root.elements[XIL_LOOP],options) if document_root.elements[XIL_LOOP]
        
        # display of the PDF document.
        code+=options[:pdf]+"="+options[:pdf]+".Output() \n"
       
        # data savings in the impression table and creation of appropriate folders and files.
        if options[:archive].eql? :impression
          code+="binary_digest=Digest::SHA256.hexdigest("+options[:pdf]+")\n"
          code+="unless ::"+@@xil_options[:impression_model]+".exists?(['template_md5 = ? AND key = ? AND sha256 = ?','"+options[:name]+"',"+options[:key]+",'+binary_digest+'])\n"
          code+="impression=::"+@@xil_options[:impression_model]+".create!(:key=>"+options[:key]+",:template_md5=>'"+options[:name]+"', :sha256=>binary_digest, :original_name=>"+options[:title]+", :printed_at=>Time.now,:company_id=>"+options[:current_company].id.to_s+",
:filename=>'t')\n"
          code+=options[:storage]+"='"+@@xil_options[:impressions_path]+"/'+(impression.id/"+@@xil_options[:subdir_size].to_s+").to_i.to_s+'/'\n"
          code+="Dir.mkdir("+options[:storage]+") unless File.directory?("+options[:storage]+")\n"
          code+=options[:file]+"=File.open("+options[:storage].to_s+"+impression.id.to_s,'wb')\n"
          code+=options[:file]+".write("+options[:pdf]+")\n"
          code+=options[:file]+".close()\n"
          code+="impression.filename="+options[:storage]+"+impression.id.to_s\n"
          code+="impression.save!\n"
          code+="end\n"
        end
                
        # execution of the PDF document.
        code+="send_data "+options[:pdf]+", :filename=>"+options[:title]+"\n"
        code+="end\n" 
        
        
        module_eval(code)
        code
        
      end
      
      # a XML element has a value for a attribute or not. In this case, a default value is given.
      def attribute(element, attribute, default=nil)
        if default.nil?
          element.attributes[attribute.to_s]
        else
          element.attributes[attribute.to_s]||default 
        end
      end

      # the height format of the page.
      def format_height(format, unit)
        coefficient = FPDF.scale_factor(unit)
        FPDF.format(format,coefficient)[1].to_f/coefficient
      end
      
      # this function test if the balise info exists in the template and adds it in the code.	
      def analyze_infos(infos,options={})
        code=''
        # saving of the informations concerning authors and creators of the PDF document.
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
        query = title.attributes['query']
        
        # the title could be created as from an attribute query or not.
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
      

      # this function test if the balise loop exists in the template and adds it in the code.	
      def analyze_loop(loop, options={})
        options[:depth] += 1
        code=''
        attrs = loop.attributes
        
        # there are many balises loop imbricated in the template.
        if options[:depth]>=1 
          options[:specials][options[:depth]]={}
          options[:specials][options[:depth]][:header]=(options[:specials][options[:depth]-1][:header]).dup
          options[:specials][options[:depth]][:footer]=(options[:specials][options[:depth]-1][:footer]).dup
        end
        
        raise Exception.new("You must specify a name beginning by a character for the element loop (2 characters minimum): "+attrs['name'].to_s) unless attrs['name'].to_s=~/^[a-z][a-z0-9]+$/
        result=attrs["name"]
        
        options[:fields]={} if options[:fields].nil?
        query=attrs['query']
        
        # texts in the PDF document could be created as from an attribute query. 
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

        # course of the different elements or block containing in a loop.
        loop.each_element do |element|
          depth=options[:depth]
          # the block is a header or a footer.
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
            # the block can have an attribute query.
            unless element.attributes['if'].nil?
              condition=element.attributes['if']
              query = 'SELECT ('+condition+')::BOOLEAN AS x'
              code+="if c.select_one(\'"+clean_string(query, options,true)+"\')[\"x\"]==\"t\"\n"
            end
            
            # before displaying the block, it is necessary to verify if the block can be add into a page. Otherwise,
            # a new page is created with the function analyze_page_break and the appropriate header too.
            if element.name==XIL_BLOCK
              block_height = block_height(element)
              bhfe = block_height(options[:specials][depth][:footer][:even])
              bhfo = block_height(options[:specials][depth][:footer][:odd])
              
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
        code+=analyze_footer(options) if options[:depth]==0
        code+="end\n" if query
        code.to_s
      end
      
      #  this function test if the balise block exists in the template and adds it in the code.	     
      def analyze_block(block, options={})
        code=''
        block_height = block_height(block)
        
        # ca fonctionne
        #unless options[:format].split('x')[1].to_i >= block_height(block) and options[:format].split('x')[0].to_i >= block_width(block) 
        # raise Exception.new("Sorry, You have a block which bounds are incompatible with the format specified.")
        # puts block_width(block).to_s+"x"+block_height(block).to_s+":"+options[:format]
        #end
        
        # when each blocks are analyzing, it content (text, image, line, rectangle) is readed. 
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
      
      # the height of a block must be known before display in the page.
      def block_height(block)
        height=0
        block.each_element do |element|
          attrs = element.attributes
          case element.name
          when 'line'
            h=attrs['y1'].to_f>attrs['y2'].to_f ? attrs['y1'].to_f : attrs['y2'].to_f
          else
            h=attrs['y'].to_f+attrs['height'].to_f
          end
          height=h if h>height
        end
        h = block.attributes['height']||0
        return height>h ? height : h
      end 
      
      # the width of a block must be known before display in the page.
      def block_width(block)
        width=0
        block.each_element do |element|
          attrs = element.attributes
          case element.name
          when 'line'
            w=attrs['x1'].to_f>attrs['x2'].to_f ? attrs['x1'].to_f : attrs['x2'].to_f
          else
            w=attrs['x'].to_f+attrs['width'].to_f
          end
          width=w if w>width
        end
        w = block.attributes['width']||0
        return width>h ? width : w
      end 

      # this function is called when a new page is necessary for the PDF document.
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
      
      # this function is called when a header is necessary for the PDF document.
      def analyze_header(options={})
        code=""
        unless options[:specials].empty?
          unless options[:specials][options[:depth]].nil?
            unless options[:specials][options[:depth]][:header].nil?
              so = analyze_block(options[:specials][options[:depth]][:header][:odd],options)
              se = analyze_block(options[:specials][options[:depth]][:header][:even],options)
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
      
      # this function is called when a footer is necessary for the PDF document.
      def analyze_footer(options={})
        code=""
        unless options[:specials].empty?
          unless options[:specials][options[:depth]].nil?
            unless options[:specials][options[:depth]][:footer].nil?
              so = analyze_block(options[:specials][options[:depth]][:footer][:odd],options)
              se = analyze_block(options[:specials][options[:depth]][:footer][:even],options)
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
      
      
      # when a balise text is read in the template.  
      def analyze_text(text, options={})
        code=''
        attrs=text.attributes
        #      raise Exception.new("Your text is out of the block") unless attrs['y'].to_i < attrs['width'].to_i
        color=attrs['color']||options[:defaults]['color']
        family=attrs['family']||options[:defaults]['family']
        size=attrs['size']||options[:defaults]['size']
        if attrs['border-color'] or attrs['border-width'] or attrs['background-color']
          code+=analyze_rectangle(text,options)
        end
        style = ''
        style += 'B' if attrs['weight']=='bold'
        style += 'U' if attrs['decoration']=='underline'
        style += 'I' if attrs['style']=='italic'
        code+=options[:pdf]+".set_text_color("+color_to_rvb(color)+")\n"
        code+=options[:pdf]+".set_font('"+family+"','"+style+"',"+size.to_s+")\n" 
        code+=options[:pdf]+".cell("+attrs['width']+","+attrs['height']+",'"+
          clean_string(text.text.to_s, options)+"',0,0,'"+attrs['align']+"',false)\n"
        code.to_s
      end 
      
      # when a balise image is read in the template.
      def analyze_image(image,options={})
        code=''
        attrs=image.attributes
        code+=options[:pdf]+".image('"+attrs['src']+"',"+attrs['x']+","+options[:block_y]+"+"+attrs['y']+","+attrs['width']+","+attrs['height']+")\n"   
        code.to_s
      end

      # when a balise line is read in the template.
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
          
      # if the user wishes to load a template to make the impression (facture). 
      if new_options[:features].include? :template
        if new_options[:template_model_name].is_a? Symbol
          new_options[:template_model]=new_options[:template_model_name].to_s.singularize.classify 

          # the model of template specified by the user must contain particular fields.
          ["id", "content","cache","company_id"].detect do |field|
            raise Exception.new("The table of template #{new_options[:template_model]} must contain at least the following field: "+field) unless eval(new_options[:template_model]).column_names.include? field
          end
            
        else
          raise Exception.new("The name of the #{new_options[:template_model_name]} is not a symbol.")
        end
      end  
      Ekylibre::Xil::ClassMethods::xil_options=new_options
    end
  end
end






