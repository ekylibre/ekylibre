module Ekylibre
  module Xil

    class Template
      
      PDF_DEFAULT_UNIT = 'pt'
      PDF_DEFAULT_FORMAT = Ekylibre::Xil::Style::FORMATS[Ekylibre::Xil::Style::DEFAULT_FORMAT]
      PDF_DEFAULT_MARGIN = [Ekylibre::Xil::Measure.new('0m')]*4

      def compile_for_pdf(method_name, environment)
        environment[:output] ||= :pdf
        element = @xil.root
        @formats = {}

        # code  = ''
        # code += browse(element, environment)
        # code
        code  = "def #{method_name}(options={})\n"
        code += pdf_template(element, environment).gsub(/^/, '  ')
        code += "end\n"
      end
      
      private
      
      def pdf_template(element, environment={})
        environment[:pdf]              = 'pdf' # FPDF object.

        environment[:covered]          = 'covered' # before_y.
        environment[:remaining]        = 'remains' # after_y.
#        environment[:available_height] = 'h' # height of the page available in the time.
        environment[:page_number]      = 'page_number' # page_number.
        environment[:count]            = 'page_block_count' # block_number in the current page.
        environment[:now]              = 'time_now' # timestamp NOW.
#        environment[:title]            = 'g' # title of the document.
#        environment[:temp]             = XIL_TITLE # temporary variable.
#        environment[:key]              = 'k'
#        environment[:depth]            = -1 # depth of the different balises loop imbricated.
#        environment[:permissions]      = [:copy,:print]
#        environment[:file_name]        = 'o'  # file with the extension.

        code  = ''
        
        
        code += browse(element, environment)
        
#        code += "#{environment[:pdf]} = #{environment[:pdf]}.Output()\n"
#        code += environment[:file_name]+"="+environment[:title]+".gsub(/[^a-z0-9\_]/i,'_')+'."+environment[:output].to_s+"'\n"

        # if a storage of the PDF document is implied by the user.
#        if @@xil_environment[:features].include? :document
#          code+="ActionController::Base.save_document(_mode,"+environment[:key]+","+environment[:file_name]+","+environment[:pdf]+",@"+environment[:current_company].to_s+")\n"
#        end

        # displaying of the PDF document.
        # code += "puts #{environment[:pdf]}.generate\n"
        code += "send_data(#{environment[:pdf]}.generate, :filename=>'file.pdf', :disposition=>'inline', :type=>'application/pdf')\n"

        code
      end


      
      def pdf_formats(element, environment={})
        code  = ''
        code += browse(element, environment)
        code
      end

      def pdf_format(element, environment={})
        attrs = element.attributes
        @formats[attrs['rule']] = Ekylibre::Xil::Style.new(attrs['style'])
        code  = ''
        code += "# #{attrs['rule']} { #{attrs['style']} }\n"
        code
      end



      def pdf_parameters(element, environment={})
        code  = ''
        code += browse(element, environment)
        code
      end

      def pdf_parameter(element, environment={})
        attrs = element.attributes
        name = attrs['name']
        raise Exception.new('Unvalid parameter name: '+name) unless name.match /^[a-zA-Z]\w+$/
        default = attrs['default']
        nature = attrs['nature']
        if default
          if nature=='boolean'
            default = (default=="true")
          elsif nature == 'integer'
            default = default.to_i
          elsif nature != 'text'
            raise Exception.new("Parameter #{name} can't support a default value.")
          end
        end
        code  = ''
        code += "#{name} = options[:#{name}]"
        code += "||#{default.inspect}" if default
        code += "\n"
        code += "raise Exception.new('Option :#{name} must be given') if #{name}.nil?\n" unless default
        code
      end




      
      def pdf_document(element, environment={})
        code  = ''
        code += environment[:pdf]+" = Spdf.new\n"
        code += "ic = Iconv.new('ISO-8859-15', 'UTF-8')\n"
        # code += environment[:page_number]+" = 1\n"
        code += browse(element, environment)
        code
      end
      
      def pdf_page(element, environment={})
        attrs = element.attributes
        style = Ekylibre::Xil::Style.new(attrs['style'])
        # environment[:page] = {:orientation=>ORIENTATION[attrs['orientation']], :format=>attrs['format']}
        # environment[:page][:margin_top] = style.get('margin')[0]
        # style.set('height', format_height(options[:format],options[:unit])-options['margin_top']-options['margin_bottom'])
        puts style.get('margin').inspect
        environment[:page] = {}
        environment[:page][:style]  = style
        environment[:page][:margin] = (style.get('margin')||PDF_DEFAULT_MARGIN).collect{|l| l.to_f(PDF_DEFAULT_UNIT).round(3)}
        environment[:page][:format] =   (style.get('size')||PDF_DEFAULT_FORMAT).collect{|l| l.to_f(PDF_DEFAULT_UNIT).round(3)}
        environment[:page][:rotate] = style.get('rotate', '0deg').to_f('deg')
        code  = pdf_new_page(environment)
        code += browse(element, environment)
        code
      end

      def pdf_loop(element, environment={})
        code  = ''
        attrs = element.attributes
        variable = attrs['for']
        finder = attrs['in']
        raise Exception.new('for attribute is missing') if variable.blank?
        raise Exception.new('in attribute is missing') if finder.blank?
        code += 'for '+variable+' in '+finder.split("#")[0]+"\n"
        code += browse(element, environment).gsub(/^/, '  ')
        code += "end\n"
        code
      end
      
      def pdf_block(element, environment={})
        code  = "# Block\n"
        attrs = element.attributes
        style = Ekylibre::Xil::Style.new(attrs['style'])
        height = style.get('height', '50mm').to_f(PDF_DEFAULT_UNIT).round(4)
        if attrs['type'].nil? or attrs['type'] == 'body'
          # Header
          # Body
          code += "pdf.line([[0,y], [#{environment[:page][:format][0]}, y+#{height/2}], [0, y+#{height}]], :border=>{:color=>'#DDF'})\n"
          code += "if y>#{environment[:page][:format][1]-height-environment[:page][:margin][2]}\n"
          code += pdf_new_page(environment).gsub(/^/, '  ')
          code += "end\n"
          code += browse(element, environment)
          code += "y += #{height}\n" if height>0
          #Footer
        end

        code
      end
      
      def pdf_set(element, environment={})
        code  = ''
        elements = browse(element, environment)
        attrs = element.attributes
        style = Ekylibre::Xil::Style.new(attrs['style'])
        left  = style.get('left','0mm').to_f(PDF_DEFAULT_UNIT).round(4)
        top   = style.get('top','0mm').to_f(PDF_DEFAULT_UNIT).round(4)
        unless elements.blank?
          code += "x += #{left}\n" if left != 0
          code += "y += #{top}\n"  if top != 0
          code += elements
          code += "y -= #{top}\n"  if top != 0
          code += "x -= #{left}\n" if left != 0
        end
        code
      end
      
      def pdf_text(element, environment={})
        code  = ''
        attrs = element.attributes
        style = @formats[element.name]
        puts '-------------------------------------------------------'
        puts style.inspect
        # style = style.merge(@formats[".#{attrs[:class]}"])
        # puts style.inspect
        style = style.merge(Ekylibre::Xil::Style.new(attrs['style']))
        puts style.inspect
        
        left   = style.get('left','0mm').to_f(PDF_DEFAULT_UNIT).round(4)
        top    = style.get('top','0mm').to_f(PDF_DEFAULT_UNIT).round(4)
        width  = style.get('width','100mm').to_f(PDF_DEFAULT_UNIT).round(4)
        height = style.get('height','10mm').to_f(PDF_DEFAULT_UNIT).round(4)
        font = {}
        font[:size]   = style.get('font-size','10pt').to_f(PDF_DEFAULT_UNIT)
        font[:family] = style.get('font-family', 'helvetica')
        font[:weight] = style.get('font-weight')
        font[:style]  = style.get('font-style')
        font.delete_if {|key, value| value.nil? } 
        code += "#{environment[:pdf]}.box(x#{left == 0 ? '' : '+'+left.to_s}, y#{top == 0 ? '' : '+'+top.to_s}, #{width}, #{height}, :font=>#{font.inspect}, :text=>#{string_clean(element.text, environment)})\n"
        code
      end
      







      def pdf_new_page(environment)
        code  = "#{environment[:pdf]}.new_page(#{environment[:page][:format].inspect}, #{environment[:page][:rotate]})\n"
        code += "x, y = #{environment[:page][:margin][3]}, #{environment[:page][:margin][0]}\n"
        code
      end










#       def analyze_template(template, options={})
#         document=REXML::Document.new(template)
#         document_root=document.root || (raise Exception.new("The template has not root."))

#         raise Exception.new("Only SQL") unless document_root.attributes['query-standard']||'sql' == 'sql'

#         environment[:orientation]=(document_root.attributes['orientation'] || ORIENTATION.to_a[0][0]).to_sym

#         raise Exception.new("Bad orientation in the template") unless ORIENTATION.include? environment[:orientation]

#         environment[:unit]             = attribute(document_root, :unit, 'mm')
#         environment[:format]           = attribute(document_root, :format, 'A4')
#         environment['margin_top']      = attribute(document_root, 'margin-top', 5).to_f
#         environment['margin_bottom']   = attribute(document_root, 'margin-bottom', 5).to_f
#         environment[:covered]          = 'b' # before_y.
#         environment[:remaining]        = 'a' # after_y.
#         environment[:available_height] = 'h' # height of the page available in the time.
#         environment[:page_number]      = 'n' # page_number.
#         environment[:count]            = 'm' # block_number in the current page.
#         environment[:pdf]              = 'pdf' # FPDF object.
#         environment[:now]              = 't' # timestamp NOW.
#         environment[:title]            = 'g' # title of the document.
#         environment[:temp]             = XIL_TITLE # temporary variable.
#         environment[:key]              = 'k'
#         environment[:depth]            = -1 # depth of the different balises loop imbricated.
#         environment[:permissions]      = [:copy,:print]
#         environment[:file_name]        = 'o'  # file with the extension.

#         # prototype of the generated function.
#         code ="def render_xil_"+environment[:name].to_s+"_"+environment[:output].to_s+"("+environment[:key]+", _mode=nil, _locals={})\n"

#         code += environment[:now]+"=Time.now\n"
#         code += environment[:title]+"='file'\n"

#         # declaration of the PDF document and first options.
#         code += environment[:pdf]+"=FPDF.new('"+ORIENTATION[environment[:orientation]]+"','"+environment[:unit]+"','" +environment[:format]+ "')\n"
#         #code += environment[:pdf]+".set_protection(["+environment[:permissions].collect{|x| ':'+x.to_s}.join(",")+"],'')\n"
#         code += environment[:pdf]+".alias_nb_pages('[[PAGENB]]')\n"
#         code += environment[:available_height]+"="+(format_height(environment[:format],environment[:unit])-environment['margin_top']-environment['margin_bottom']).to_s+"\n"
#         code += environment[:page_number]+"=1\n"
#         code += environment[:count]+"=0\n"
#         code += environment[:pdf]+".set_auto_page_break(false)\n"

#         environment[:specials]=[{}]
#         environment[:defaults]={"size"=>10, "family"=>'Arial', "color"=>'#000', "border-color"=>'#000', "border-width"=>0.2, "radius"=>0, "vertices"=>'1234'}.merge(document_root.attributes)

#         code += environment[:pdf]+".set_font('"+environment[:defaults]['family']+"','',"+environment[:defaults]['size'].to_s+")\n"
#         code += environment[:pdf]+".set_margins(0,0)\n"

#         # add the first page.
#         code += environment[:pdf]+".add_page()\n"
#         code += environment[:covered]+"="+environment['margin_top'].to_s+"\n"
#         code += environment[:remaining]+"="+environment[:available_height]+"\n"
#         code += "c=ActiveRecord::Base.connection\n"
#         code += analyze_title(document_root.elements[XIL_TITLE], options) if document_root.elements[XIL_TITLE]
#         code += analyze_infos(document_root.elements[XIL_INFOS],options) if document_root.elements[XIL_INFOS]
#         code += analyze_loop(document_root.elements[XIL_LOOP],options) if document_root.elements[XIL_LOOP]

#         code += environment[:pdf]+"="+environment[:pdf]+".Output()\n"
#         code += environment[:file_name]+"="+environment[:title]+".gsub(/[^a-z0-9\_]/i,'_')+'."+environment[:output].to_s+"'\n"

#         # if a storage of the PDF document is implied by the user.
#         if @@xil_environment[:features].include? :document
#           code += "ActionController::Base.save_document(_mode,"+environment[:key]+","+environment[:file_name]+","+environment[:pdf]+",@"+environment[:current_company].to_s+")\n"

#         end

#         # displaying of the PDF document.
#         code += "send_data "+environment[:pdf]+", :filename=>"+environment[:file_name]+"\n"
#         code += "end\n"

#         # in commentary, test the generate code putting it in a code.
#         if RAILS_ENV=="development"
#           f=File.open('/tmp/test.rb','wb')
#           f.write(code)
#           f.close()
#         end

#         module_eval(code)
#       end

#       # if the attribute of an element has a value. Otherwise, a default value is used.
#       def attribute(element, attribute, default=nil)
#         if default.nil?
#           element.attributes[attribute.to_s]
#         else
#           element.attributes[attribute.to_s]||default
#         end
#       end

#       # the format height of the page computed as from the format specifying in the template.
#       def format_height(format, unit)
#         coefficient = FPDF.scale_factor(unit)
#         FPDF.format(format,coefficient)[1].to_f/coefficient
#       end

#       # this function test if the balise info exists in the template and adds it in the code. Mainly informations
#       # as title, author identity, date ... are saved.
#       def analyze_infos(infos,options={})
#         code=''
#         infos.each_element(XIL_INFO) do |info|
#           case info.attributes['type']
#           when "subject-on"
#             code += environment[:pdf]+".set_subject('#{info.text}')\n"
#           when "written-by"
#             code += environment[:pdf]+".set_author('#{info.text}')\n"
#           when "created-by"
#             code += environment[:pdf]+".set_creator('#{info.text}')\n"
#           end
#         end
#         code.to_s
#       end


#       # this function test if the balise title exists in the template and adds it in the code.	
#       def analyze_title(title,options={})
#         code=''
#         query=title.attributes['query']
#         # if the title is created as from a query.
#         if query=~/^SELECT\ [^;]*$/i
#           result=environment[:temp]
#           environment[:fields]={} if environment[:fields].nil?
#           query.split(/\ from\ /i)[0].to_s.split(/select\ /i)[1].to_s.split(',').each do |s|
#             environment[:fields][result+'.'+s.downcase.strip] = result+"[\""+s.downcase.strip+"\"].to_s"
#           end
#           code += result+"=c.select_one(\'"+clean_string(query, options,true)+"\')\n"
#         end
#         code += environment[:title]+"='"+clean_string(title.text,options)+"'\n"
#         code.to_s
#       end

#       # this function runs the different elements loop in the template and analyzes each of it. 	
#       def analyze_loop(loop, options={})
#         environment[:depth]+=1
#         # if no blocks header and footer has been still encountered, the heights of these blocks are
#         # valuated to the empty block.
#         environment[:specials][environment[:depth]]={}
#         environment[:specials][environment[:depth]][:header]={}
#         environment[:specials][environment[:depth]][:footer]={}
#         environment[:specials][environment[:depth]][:header][:even]=Element.new(XIL_BLOCK)
#         environment[:specials][environment[:depth]][:header][:odd] =Element.new(XIL_BLOCK)
#         environment[:specials][environment[:depth]][:footer][:odd] =Element.new(XIL_BLOCK)
#         environment[:specials][environment[:depth]][:footer][:even]=Element.new(XIL_BLOCK)

#         code=''
#         attrs=loop.attributes

#         # in the case where many elements loop are imbricated, a variable of depth is precised
#         # to better save the results of query returned by each them.
#         if environment[:depth]>=1
#           environment[:specials][environment[:depth]]={}
#           environment[:specials][environment[:depth]][:header]=(environment[:specials][environment[:depth]-1][:header]).dup
#           environment[:specials][environment[:depth]][:footer]=(environment[:specials][environment[:depth]-1][:footer]).dup
#         end

#         raise Exception.new("You must specify a name beginning by a character for the element loop (2 characters minimum): "+attrs['name'].to_s) unless attrs['name'].to_s=~/^[a-z][a-z0-9]+$/
#         result=attrs["name"]

#         environment[:fields]={} if environment[:fields].nil?
#         query=attrs['query']

#         # if a query is present as an attribute in the balise loop then, the query is executed and the results saved.
#         if query
#           if query=~/^SELECT\ [^;]*$/i
#             query.split(/\ from\ /i)[0].to_s.split(/select\ /i)[1].to_s.split(',').each do |s|
#               environment[:fields][result+'.'+s.downcase.strip] = result+"[\""+s.downcase.strip+"\"].to_s"
#             end
#             code += "for "+result+" in c.select_all('"+clean_string(query,options,true)+"')\n"
#           else
#             raise Exception.new("Invalid SQL query. Maybe there is an SQL injection.")
#           end
#         else
#           code += result+"=[]\n"
#         end

#         # begin to run the elements loop.
#         loop.each_element do |element|
#           depth=environment[:depth]
#           # verify if it is a header or a footer block and compute the parameters of the block
#           # as the height ...
#           if (element.attributes['type']=='header' or element.attributes['type']=='footer')
#             mode=attribute(element, :mode, 'all').to_sym
#             type=attribute(element, :type, 'header').to_sym
#             environment[:specials]=[] unless environment[:specials].is_a? Array
#             environment[:specials][depth]={} unless environment[:specials][depth].is_a? Hash
#             environment[:specials][depth][type]={} unless environment[:specials][depth][type].is_a? Hash
#             if mode==:all
#               environment[:specials][depth][type][:even] = element.dup
#               environment[:specials][depth][type][:odd]  = environment[:specials][depth][type][:even]
#             else
#               environment[:specials][depth][type][mode] = element.dup
#             end
 
#           else
#             # if a conditional attribute is precised for this element.
#             unless element.attributes['if'].nil?
#               condition=element.attributes['if']
#               query = 'SELECT ('+condition+')::BOOLEAN AS x'
#               code += "if c.select_one(\'"+clean_string(query, options,true)+"\')[\"x\"]==\"t\"\n"
#             end
 
#             # if the block considered is not a header or footer's block.
#             if element.name==XIL_BLOCK
#               block_height = block_height(element)
   
#               bhfe = block_height(environment[:specials][depth][:footer][:even])
#               bhfo = block_height(environment[:specials][depth][:footer][:odd])

#               # if the height of the block is bigger than the remaining height of the page, a new
#               # page is created and the appropriate header sets in.
#               code += "if("+environment[:covered]+"=="+environment['margin_top'].to_s+")\n"+analyze_header(options)+"end\n" unless environment[:specials].empty?
   
#               if bhfe==bhfo
#                 code += "if("+environment[:count]+"==0 and "+environment[:remaining]+"<"+(block_height+bhfe).to_s+")\nraise Exception.new('Footer too big.')\n"
#                 code += "elsif("+environment[:remaining]+"<"+(block_height+bhfe).to_s+")\n"
#               else
#                 code += "if("+environment[:count]+"==0 and "+environment[:remaining]+"<"+block_height.to_s+"+"+bhfe.to_s+" and "+environment[:remaining]+"<"+bhfo.to_s+")\nraise Exception.new('Footer too big.')\n"
#                 code += "elsif("+environment[:remaining]+"<"+block_height.to_s+"+("+environment[:page_number]+".even? ? "+bhfe.to_s+":"+bhfo.to_s+"))\n"
#               end
   
#               code += analyze_page_break(element,options)+"\n"
#               code += "end\n"
#               code += environment[:count]+"+=1\n"
#             end
#             code += self.send('analyze_'+ element.name.gsub("-","_"),element, options.dup) if [XIL_LOOP, XIL_BLOCK, XIL_PAGEBREAK].include?(element.name)
#             code += "end\n" unless element.attributes['if'].nil?
#             #            code += conditionalize(proc, element.attributes['if'], options)
#           end

#         end
#         # the footer block is settled in the last page of the PDF document.
#         code += analyze_footer(options) if environment[:depth]==0
#         code += "end\n" if query
#         code.to_s
#       end

#       def conditionalize(proc, element, options={})
#         code = proc
#         unless element.attributes['if'].nil?
#           query = 'SELECT ('+element.attributes['if'].to_s+')::BOOLEAN AS x'
#           code = "if c.select_one(\'"+clean_string(query, options, true)+"\')[\"x\"]==\"t\"\n"+code+"end\n"
#         end
#         code
#       end


#       # runs each blocks and analyzes them.
#       def analyze_block(block, options={})
#         code=''
#         block_height=block_height(block)

#         # it runs.
#         #unless environment[:format].split('x')[1].to_i >= block_height(block) and environment[:format].split('x')[0].to_i >= block_width(block)
#         # raise Exception.new("Sorry, You have a block which bounds are incompatible with the format specified.")
#         # puts block_width(block).to_s+"x"+block_height(block).to_s+":"+environment[:format]
#         #end

#         # runs the elements of a block as text, image, line and rectangle.
#         block.each_element do |element|
#           attrs=element.attributes
#           case element.name
#           when 'line'
#             code += environment[:pdf]+".set_xy("+attrs['x1']+","+environment[:covered]+"+"+attrs['y1']+")\n"
#           else
#             raise  Exception.new("Unvalid markup tag "+element.name+" ("+element.inspect+")") if attrs['x'].blank? or attrs['y'].blank?
#             code += environment[:pdf]+".set_xy("+attrs['x']+","+environment[:covered]+"+"+attrs['y']+")\n"
#           end
#           code += self.send('analyze_'+ element.name,element,options).to_s if [XIL_TEXT,XIL_IMAGE,XIL_LINE,XIL_RECTANGLE].include? element.name
#         end
#         if block_height > 0
#           code += environment[:covered]+"+="+block_height.to_s+"\n"
#           code += environment[:remaining]+"-="+block_height.to_s+"\n"
#         end
#         conditionalize(code.to_s,block,options)
#       end

#       # computes the height of the considered block.
#       def block_height(block)
#         height=0
#         block.each_element do |element|
#           attrs=element.attributes
#           case element.name
#           when 'line'
#             h=attrs['y1'].to_f>attrs['y2'].to_f ? attrs['y1'].to_f : attrs['y2'].to_f
#           else
#             h=attrs['y'].to_f+attrs['height'].to_f
#           end
#           height=h if h>height
#         end
#         h=block.attributes['height'].to_f||0
#         return height>h ? height : h
#       end

#       # computes the width of the considered block.
#       def block_width(block)
#         width=0
#         block.each_element do |element|
#           attrs=element.attributes
#           case element.name
#           when 'line'
#             w=attrs['x1'].to_f>attrs['x2'].to_f ? attrs['x1'].to_f : attrs['x2'].to_f
#           else
#             w=attrs['x'].to_f+attrs['width'].to_f
#           end
#           width=w if w>width
#         end
#         w=block.attributes['width']||0
#         return width>h ? width : w
#       end

#       # a new page is created and added to the PDF document.
#       def analyze_page_break(page_break,options={})
#         code=""
#         code += analyze_footer(options)
#         code += environment[:pdf]+".add_page()\n"
#         code += environment[:count]+"=0\n"
#         code += environment[:page_number]+"+=1\n"
#         code += environment[:covered]+"="+environment['margin_top'].to_s+"\n"
#         code += environment[:remaining]+"="+environment[:available_height].to_s+"\n"
#         code += analyze_header(options)
#         conditionalize(code.to_s,page_break,options)
#       end

#       # runs and analyzes each header blocks in the template.
#       def analyze_header(options={})
#         code=""
#         unless environment[:specials].empty?
#           unless environment[:specials][environment[:depth]].nil?
#             unless environment[:specials][environment[:depth]][:header].nil?
#               so=analyze_block(environment[:specials][environment[:depth]][:header][:odd],options)
#               se=analyze_block(environment[:specials][environment[:depth]][:header][:even],options)
#               if so!=se
#                 code += "if "+environment[:page_number]+".even?\n"+se+"else\n"+so+"end\n"
#               else
#                 code += se
#               end
#             end
#           end
#         end
#         code.to_s
#       end

#       # runs and analyzes each footer blocks in the template.
#       def analyze_footer(options={})
#         code=""
#         unless environment[:specials].empty?
#           unless environment[:specials][environment[:depth]].nil?
#             unless environment[:specials][environment[:depth]][:footer].nil?
#               so=analyze_block(environment[:specials][environment[:depth]][:footer][:odd],options)
#               se=analyze_block(environment[:specials][environment[:depth]][:footer][:even],options)
#               if so!=se
#                 code += "if "+environment[:page_number]+".even?\n"
#                 code += environment[:covered]+"+="+environment[:remaining]+"-"+block_height(environment[:specials][environment[:depth]][:footer][:even]).to_s+"\n"
#                 code += se
#                 code += "else\n"
#                 code += environment[:covered]+"+="+environment[:remaining]+"-"+block_height(environment[:specials][environment[:depth]][:footer][:odd]).to_s+"\n"
#                 code += so
#                 code += "end\n"
#               else
#                 code += environment[:covered]+"+="+environment[:remaining]+"-"+block_height(environment[:specials][environment[:depth]][:footer][:odd]).to_s+"\n"
#                 code += se
#               end
#             end
#           end
#         end
#         code.to_s
#       end


#       # runs and analyzes each text elements in the template with specific attributes as color, font, family...
#       def analyze_text(text, options={})
#         code=''
#         attrs=text.attributes
#         #raise Exception.new("Your text is out of the block") unless attrs['y'].to_i < attrs['width'].to_i
#         color=attrs['color']||environment[:defaults]['color']
#         family=attrs['family']||environment[:defaults]['family']
#         size=attrs['size']||environment[:defaults]['size']
#         if attrs['border-color'] or attrs['border-width'] or attrs['background-color']
#           code += analyze_rectangle(text,options)
#         end
#         style=''
#         style+='B' if attrs['weight']=='bold'
#         style+='U' if attrs['decoration']=='underline'
#         style+='I' if attrs['style']=='italic'
#         code += environment[:pdf]+".set_text_color("+rvb_to_num(color)+")\n"
#         code += environment[:pdf]+".set_font('"+family+"','"+style+"',"+size.to_s+")\n"
#         code += environment[:pdf]+".cell("+attrs['width']+","+attrs['height']+",'"+
#           clean_string(text.text.to_s, options)+"',0,0,'"+attrs['align']+"',false)\n"
#         conditionalize(code.to_s, text, options)
#       end

#       # runs and analyzes each image elements in the template with specific attributes as width, height.
#       def analyze_image(image,options={})
#         code=''
#         attrs=image.attributes
#         code += environment[:pdf]+".image('"+attrs['src']+"',"+attrs['x']+","+environment[:covered]+"+"+attrs['y']+","+attrs['width']+","+attrs['height']+")\n"
#         #        code.to_s
#         conditionalize(code.to_s, image, options)
#       end

#       # runs and analyzes each line elements in the template.
#       def analyze_line(line,options={})
#         code=''
#         attrs=line.attributes
#         border_color=attrs['border-color']||environment[:defaults]['border-color']
#         border_width=attrs['border-width']||environment[:defaults]['border-width']
#         code += environment[:pdf]+".set_draw_color("+rvb_to_num(border_color)+")\n"
#         code += environment[:pdf]+".set_line_width("+border_width.to_s+")\n"
#         code += environment[:pdf]+".line("+attrs['x1']+","+environment[:covered]+"+"+attrs['y1']+","+
#           attrs['x2']+","+environment[:covered]+"+"+attrs['y2']+")\n"
#         #        code.to_s
#         conditionalize(code.to_s, line, options)
#       end

#       # runs and analyzes each rectangle element in the template.
#       def analyze_rectangle(rectangle,options={})
#         code=''
#         attrs=rectangle.attributes
#         radius=attribute(rectangle,'radius',environment[:defaults]['radius'])
#         vertices=attribute(rectangle,'vertices',environment[:defaults]['vertices'])
#         style=''
#         if attrs['background-color']
#           code += environment[:pdf]+".set_fill_color("+rvb_to_num(attrs['background-color'])+")\n"
#           style+='F'
#         end
#         if attrs['background-color'].nil? or attrs['border-color'] or attrs['border-width']
#           border_color=attrs['border-color']||environment[:defaults]['border-color']
#           border_width=attrs['border-width']||environment[:defaults]['border-width']
#           code += environment[:pdf]+".set_line_width("+border_width.to_s+")\n"
#           code += environment[:pdf]+".set_draw_color("+rvb_to_num(border_color)+")\n"
#           style+='D'
#         end
#         code += environment[:pdf]+".rectangle("+attrs['x']+","+environment[:covered]+"+"+attrs['y']+
#           ","+attrs['width']+","+attrs['height']+","+radius.to_s+",'"+style+"','"+vertices+"')\n"
#         #        code.to_s
#         conditionalize(code.to_s, rectangle, options)
#       end

#       # converts the color attribute of an element in a better format easier to understand by the plugin.
#       def rvb_to_num(color)
#         color = color.to_s
#         color="#"+color[1..1]*2+color[2..2]*2+color[3..3]*2 if color=~/^\#[a-f0-9]{3}$/i
#         if color=~/^\#[a-f0-9]{6}$/i
#           color[1..2].to_i(16).to_s+","+color[3..4].to_i(16).to_s+","+color[5..6].to_i(16).to_s
#         else
#           raise Exception.new color.to_s
#           '255,0,255'
#         end
#       end

#       # cleans the string removing superfluous characters and replacing some constants.
#       def clean_string(string,options,query=false)
#         string.gsub!("'","\\\\'")
#         environment[:fields] = {} if environment[:fields].nil?
#         if query
#           environment[:fields].each{|f| string.gsub!("\#{"+f[0]+"}","\\\\'\'+"+f[1]+"+\'\\\\'")}
#         else
#           environment[:fields].each{|f| string.gsub!("\#{"+f[0]+"}","\'+"+f[1]+"+\'")}
#         end
#         while (string=~/[^\#]\{[A-Z\_].*.\}/)
#           str=string.split('{')[1].split('}')[0]
#           if str=~/CURRENT_DATE.*/ or str=~/CURRENT_TIMESTAMP.*/
#             if (str.match ':').nil?
#               format="%Y-%m-%d"
#               format+=" %H:%M" if str=="CURRENT_TIMESTAMP"
#             else
#               format=str.split(':')[1]
#             end
#             string.gsub!("{"+str+"}",'\'+'+environment[:now]+'.strftime(\''+format+'\')+\' ')
#           elsif str=~/LOCAL\:.*/
#             string.gsub!("{"+str+"}",'\'+_locals[:'+str.split(':')[1]+'].to_s+\'')
#           elsif str=~/KEY/
#             string.gsub!("{"+str+"}",'\'+'+environment[:key]+'.to_s+\'')
#           elsif str=~/TITLE/
#             string.gsub!("{"+str+"}",'\'+'+environment[:title]+'.to_s+\'')
#           elsif str=~/PAGENO/
#             string.gsub!("{"+str+"}",'\'+'+environment[:page_number]+'.to_s+\'')
#           elsif str=~/PAGENB/
#             string.gsub!("{"+str+"}",'[[PAGENB]]')
#           else
#             string.gsub!("{"+str+"}",'['+str+']')
#           end
#         end

#         while (string=~/\@\@.+\@\@/)
#           str=string.split('@@')[1]
#           string.gsub!('@@'+str+'@@', "'+"+environment[:pdf]+".add_label('[["+str+"]]')+'")
#         end


#         # the string is converted to the format ISO, which is more efficient for the PDF softwares to read the
#         # superfluous characters.
#         Iconv.iconv('ISO-8859-15','UTF-8',string).to_s
#       end
#     end


















      

    end

  end
end
