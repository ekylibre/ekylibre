# -*- coding: utf-8 -*-
module Templating::Compilers
  module Xil
    class Xil20

      class << self

        SCHEMA = Templating::Compilers::Xil::Schema::Definition.new(:xil20) do
          element("template") do
            has :many, "document"
          end
          element("document", "title"=>:string, "subject"=>:string, "author"=>:string, "keywords"=>:string) do
            has :many, "page", "iteration"
          end
          element("page", "format"=>:page_format, "orientation"=>:symbol, "margin"=>:length4) do
            has :many, "part", "table", "iteration"
          end
          element("part", "height"=>:length, "bottom"=>:boolean) do
            has :many, "set", "iteration"
          end
          element("table", "collection!"=>:variable, "variable"=>:variable) do
            has :many, "column"
          end
          element("list", "collection!"=>:variable, "variable"=>:variable, "columns"=>:integer, "size"=>:length, "font"=>:string)
          element("column", "label!"=>:string, "property!"=>:property, "width!"=>:length, "align"=>:symbol, "format"=>:symbol, "numeric"=>:symbol, "separator"=>:string, "delimiter"=>:string, "unit"=>:string, "precision"=>:integer, "scale"=>:integer)
          element("set", "left"=>:length, "top"=>:length, "right"=>:length) do
            has :many, "set", "iteration", "text", "cell", "rectangle", "line", "image", "list"
          end
          element("iteration", "collection!"=>:variable, "variable!"=>:variable) do
            has :many, "page", "part", "table", "list", "set", "iteration"
          end
          element("text", {"value"=>:string, "left"=>:length, "right"=>:length, "top"=>:length, "width"=>:length, "align"=>:symbol, "bold"=>:boolean, "italic"=>:boolean, "size"=>:length, "color"=>:color, "valign"=>:symbol, "border"=>:stroke, "font"=>:string}, :string)
          # element("cell", "string", "left"=>:length, "top"=>:length, "align"=>:symbol, "bold"=>:boolean, "italic"=>:boolean, "size"=>:length, "color"=>:color, "width"=>:length, "font"=>:string})
          element("rectangle", "width!"=>:length, "height!"=>:length, "left"=>:length, "top"=>:length, "right"=>:length, "border"=>:stroke)
          element("line", "path!"=>:path, "width"=>:length, "border"=>:stroke)
          element("image", "value!"=>:string, "width"=>:length, "height"=>:length, "left"=>:length, "top"=>:length) do
            has :many, "set", "iteration", "text", "cell", "rectangle", "line", "image", "list"
          end
        end


        # Main method which compile an XIL/XML Doc to ruby code
        # @param [XML::Document] doc Document to compile
        # @param [Hash] options Options for compiler
        # @return [String] Ruby code (using Templating::Writer)
        def compile(doc, options={})
          @mode = options.delete(:mode) || :normal
          template = doc.root
          code = ""
          i = 0
          parameters = template.find('parameters/parameter')
          if @mode != :debug and parameters.size > 0
            code << "raise ArgumentError.new('Unvalid number of argument') if args.size != #{parameters.size}\n"
            parameters.each do |p|
              code << "#{p.attributes['name']} = args[#{i}]\n"
              i+=1
            end
          end
          document = template.find('document')[0]
          info = parameters_hash(document, nil)
          info = hash_to_code(info)
          info = ', '+info unless info.blank?
          code << "Templating::Writer.generate(:default_font=>{:name=>'Times-Roman', :size=>10}, :creator=>'Templating #{Templating.version}'#{info}#{', :debug=>true' if @mode == :debug}) do |_d|\n"
          code << compile_children(document, '_d').strip.gsub(/^/, '  ')+"\n"
          code << "end"
          # list = code.split("\n"); list.each_index{|x| puts((x+1).to_s.rjust(4)+": "+list[x])}
          return "# encoding: utf-8\n"+'('+(@mode==:debug ? code : code.gsub(/\s*\n\s*/, ';'))+')'
          # return "# encoding: utf-8\n"+'('+code+')'
        end



        def hash_to_code(hash, wrapped = false)
          code = hash.collect do |k,v|
            "#{k.inspect} => " + if v.is_a? Symbol
                                   v.inspect
                                 else
                                   v.to_s
                                 end
          end.join(', ')
          if wrapped
            return '{'+code+'}'
          else
            return code
          end
        end


        def measure_to_float(string, max_width = 190.mm)
          string = string.to_s
          m = if string.match(/\-?\d+(\.\d+)?mm/)
                string[0..-3].to_d.mm
              elsif string.match(/\-?\d+(\.\d+)?\%/)
                # puts "DEPRECATED: Percentage value will be removed from XIL"
                string[0..-2].to_d * max_width / 100
              elsif string.match(/\-?\d+(\.\d+)?/)
                string.to_d
              else
                0
              end
          return m
        end


        def pt_to_s(float, precision = 3)
          magnitude = 10**precision
          ((float*magnitude).round.to_f/magnitude).to_s.gsub(/^(\-?\d+\.\d{#{precision}})\d+$/, '\1')
        end

        def attr_to_code(string, type = :string)
          value = Templating::Compilers::Xil::Schema::Attribute.read(string, type)
          if type == :string
            value = "'"+value.gsub(/\'/, '\\\\\'')+"'"
            value.gsub!(/\n/, "'+\"\\n\"+'")
            value.gsub!(/\{\{[^\}]+\}\}/) do |m|
              data = m[2..-3].to_s.gsub('\\\'', '\'').split('?')
              datum = data[0].gsub('/', '.')
              option = data[1].to_s.split('=')
              datum = case option[0]
                      when 'format'
                        "(::I18n.localize(#{datum}, :format=>:#{option[1]}) rescue (#{datum}).to_s)"
                      when 'numeric'
                        "number_with_precision(#{datum}, :separator=>',', :delimiter=>' ', :unit=>'', :precision=>2)"
                      else
                        datum
                      end
              (@mode == :debug ? "[VALUE]" : "'+#{datum}.to_s+'")
            end
            value.gsub!(/(^\'\'\+|\+\'\'$)/, '')
            value
          elsif type == :length
            pt_to_s(value)
          elsif type == :length4
            '['+value.collect{|x| pt_to_s(x)}.join(', ')+']'
          elsif [:page_format, :symbol].include?(type)
            value.inspect
          elsif type == :stroke
            # "{:width=>#{pt_to_s(value[:width])}, :style=>#{value[:style].inspect}, :color=>#{value[:color].inspect}}"
            "'#{pt_to_s(value[:width])}pt #{value[:style]} #{value[:color]}'"
          elsif type == :path
            '['+value.collect{|p| '['+pt_to_s(p[0])+', '+pt_to_s(p[1])+']'}.join(', ')+']'
          else
            value.to_s
          end
        end


        def parameters_hash(element, variable)
          name = element.name.to_sym
          attributes_hash = element.attributes.to_h
          hash = {}
          for attribute in SCHEMA[element.name].attributes
            if string = attributes_hash[attribute.name]
              # hash[attribute.name.to_sym] = attr_to_s(attribute.name, string, variable)
              hash[attribute.name.to_sym] = attr_to_code(string, attribute.type)
            elsif attribute.required?
              raise Exception.new("Attribute '#{attribute.name}' is required for element '#{name}'")
            end
          end
          if SCHEMA[element.name].has_content?
            # hash[:content] =  attr_to_s(:content, element.content, variable)
            hash[:content] =  attr_to_code(element.content, SCHEMA[element.name].content)
          end
          # hash.delete(:if)
          return hash
        end

        # Retrives true values
        def parameters_values(element)
          attributes_hash = element.attributes.to_h
          hash = {}
          for attribute in SCHEMA[element.name].attributes
            if string = attributes_hash[attribute.name]
              hash[attribute.name.to_sym] = attribute.read(string)
            elsif attribute.required?
              raise Exception.new("Attribute '#{attribute.name}' is required for element '#{name}'")
            end
          end
          if SCHEMA[element.name].has_content?
            hash[:content] = SCHEMA[element.name].read(element.content)
          end
          return hash
        end


        # Call code generation function for each children
        def compile_children(element, variable, depth=0)
          code = ''
          children = SCHEMA[element.name].children
          element.each_element do |child|
            if children.include?(child.name)
              code << compile_element(child, variable, depth).strip + "\n"
            end
          end
          return code
        end

        def execute_children(element, variable_name, depth=0)
          children = compile_children(element, variable_name, depth)
          if children.blank?
            return ""
          else
            return " do |#{variable_name}|\n"+children.strip.gsub(/^/, '  ')+"\nend\n"
          end
        end

        # Generate code for given element
        def compile_element(element, variable, depth=0)
          code  = ''
          name = element.name.to_sym
          children_variable = "_#{depth}"
          phash = parameters_hash(element, variable)
          if name == :image
            file = phash.delete(:value)
            # code << "raise [_d, _p, _s].inspect\n"
            code << "if File.exist?((#{file}).to_s)\n"
            code << "  #{variable}.image(#{file}, #{hash_to_code(phash, true)})\n"
            code << "else\n"
            code << compile_children(element, variable, depth).strip.gsub(/^/, '  ')+"\n"
            code << "end"

          elsif name == :iteration
            code << "for #{phash[:variable]} in #{phash[:collection]}\n" unless @mode == :debug
            code << compile_children(element, variable, depth).strip.gsub(/^/, '  ')+"\n"
            code << "end" unless @mode == :debug

          elsif name == :line
            points = phash.delete(:path)
            if phash[:border]
              phash[:stroke] = phash.delete(:border)
            elsif phash[:width]
              phash[:stroke] = "'#{phash.delete(:width)}pt solid #000000'"
            else
              phash[:stroke] = "'0.5pt solid #000000'"
            end
            code << "#{variable}.line(#{points[1..-2]}, #{hash_to_code(phash, true)})"

          elsif name == :list
            options = parameters_values(element)
            collection = phash.delete(:collection)
            lines = (@mode == :debug ? "[]" : collection)
            if font = options[:font]
              font = "Helvetica" if font.downcase == "helvetica"
              font = "Times-Roman" if font.downcase == "times"
              phash[:font] = "'#{font}'"
            end
            code << "#{variable}.list(#{lines}, #{hash_to_code(phash, true)})"

          elsif name == :page
            # Xil 2.0 assumes that Times 10pt is default font
            code << "#{variable}.page(:size=>#{phash[:format]}, :orientation=>#{phash[:orientation]||':portrait'}, :margins=>#{phash[:margin]||'15.mm'})"
            code << execute_children(element, "_p", depth+1)

          elsif name == :part
            # code << "(:height => #{phash[:height]})" if phash[:height]
            phash.delete(:height) if element.find(".//list[@resize='true']").size > 0
            code << "#{variable}.slice(#{hash_to_code(phash)})"
            code << execute_children(element, "_s", depth+1)

          elsif name == :rectangle
            if phash[:right]
              phash[:left] = "(#{variable}.current_box.width - #{phash.delete(:right)})"
            end
            phash[:stroke] = phash.delete(:border)
            code << "#{variable}.rectangle(#{hash_to_code(phash)})"

          elsif name == :set
            if phash.empty?
              code << compile_children(element, variable, depth)
            else
              if phash[:right]
                phash[:left] = "(#{variable}.current_box.width - #{phash.delete(:right)})"
              end
              code << "#{variable}.box(#{hash_to_code(phash)}) do\n"
              code << compile_children(element, variable, depth+1).strip.gsub(/^/, '  ')+"\n"
              code << "end\n"
            end

          elsif name == :table
            children_variable = "_s"
            collection = phash.delete(:collection)
            collection = (@mode == :debug ? "[]" : collection)
            stroke = phash.delete(:border) || "'0.5pt solid #000'"
            record = phash.delete(:variable) || '_r'
            columns = []
            start =  measure_to_float(element.attributes['left'])
            offset = start
            element.each_element do |e|
              if e.name == 'column'
                col = {:phash => parameters_hash(e, variable), :attributes=>e.attributes}
                col[:offset] = offset
                col[:width] = measure_to_float(e.attributes['width'])
                col[:align] = e.attributes["align"] || :left
                offset += col[:width]
                columns << col
              end
            end
            cell_margin = [2, 2, 1, 2]
            code << "#{variable}.slice(:height => #{pt_to_s(1.mm)})\n"
            # Header
            code << "#{variable}.slice do |#{children_variable}|\n"
            code << "  #{children_variable}.row(["
            code << columns.collect do |column|
              "{:value=>#{column[:phash][:label]}, :width=>#{pt_to_s(column[:width])}, :valign=>:center, :align=>:center, :bold=>true}"
            end.join(", ")
            code << "], :stroke=>#{stroke})\n"
            code << "end\n"
            code << "for #{record} in #{collection}\n"
            code << "  #{variable}.slice do |#{children_variable}|\n"
            code << "    #{children_variable}.row(["
            code << columns.collect do |column|
              value = "#{record}."+column[:attributes][:property].gsub(/\//, '.')
              if column[:attributes]['format']
                value = "(::I18n.localize(#{value}, :format=>#{column[:phash][:format]}) rescue (#{value}).to_s)"
                column[:phash][:align] ||= ":center"
                column[:align] = :center
              elsif column[:attributes]['numeric']
                column[:align] = :right
                curr_hash = {}
                for pair in column[:phash].select{|k,v| [:separator, :delimiter, :unit, :precision, :scale].include?(k)}
                  curr_hash[pair[0]] = pair[1]
                end
                curr_hash[:separator] ||= "','"
                curr_hash[:delimiter] ||= "' '"
                curr_hash[:unit] ||= "''"
                curr_hash[:precision] ||= '2'
                value = "number_with_precision(#{value}, #{hash_to_code(curr_hash, true)})"
                column[:phash][:align] ||= ":right"
              end
              "{:value=>#{value}.to_s, :width=>#{pt_to_s(column[:width])}, :align=>:#{column[:align]}}"
            end.join(", ")
            code << "], :stroke=>#{stroke})\n"
            code << "  end\n"
            code << "end\n"

            # code << "#{variable}.slice do |#{children_variable}|\n"
            # code << "  row_height = 0\n"
            # for column in columns
            #   code << "  _h = #{children_variable}.height_of(#{column[:phash][:label]}, :width=>#{pt_to_s(column[:width]-cell_margin[1]-cell_margin[3])})\n"
            #   code << "  row_height = _h if _h > row_height\n"
            # end
            # code << "  row_height += #{pt_to_s(cell_margin[0]+cell_margin[2])}\n"
            # for column in columns
            #   code << "  #{children_variable}.text(#{column[:phash][:label]}, :left=>#{pt_to_s(column[:offset]+cell_margin[3])}, :width=>#{pt_to_s(column[:width]-cell_margin[1]-cell_margin[3])}, :top=>#{pt_to_s(cell_margin[0])}, :height=>row_height, :valign=>:center, :align=>:center, :bold=>true)\n"
            #   code << "  #{children_variable}.line([#{pt_to_s(column[:offset])}, 0], [#{pt_to_s(column[:offset])}, row_height], :stroke=>#{stroke})\n"
            #   # code << "  row_height = _b.height if _b.height > row_height\n"
            # end
            # code << "  #{children_variable}.line([#{pt_to_s(start)}, 0], [#{pt_to_s(offset)}, 0], [#{pt_to_s(offset)}, row_height], [#{pt_to_s(start)}, row_height], :stroke=>#{stroke})\n"
            # code << "end\n"
            # # Rows
            # code << "for #{record} in #{collection}\n"
            # code << "  #{variable}.slice do |#{children_variable}|\n"
            # code << "    row_height = 0\n"
            # for column in columns
            #   value = "#{record}."+column[:attributes][:property].gsub(/\//, '.')
            #   if column[:attributes]['format']
            #     value = "::I18n.localize(#{value}, :format=>#{column[:phash][:format]})"
            #     column[:phash][:align] ||= ":center"
            #     column[:align] = :center
            #   elsif column[:attributes]['numeric']
            #     column[:align] = :right
            #     curr_hash = {}
            #     for pair in column[:phash].select{|k,v| [:separator, :delimiter, :unit, :precision, :scale].include?(k)}
            #       curr_hash[pair[0]] = pair[1]
            #     end
            #     curr_hash[:separator] ||= "','"
            #     curr_hash[:delimiter] ||= "' '"
            #     curr_hash[:unit] ||= "''"
            #     curr_hash[:precision] ||= '2'
            #     value = "number_to_currency(#{value}, #{hash_to_code(curr_hash, true)})"
            #     column[:phash][:align] ||= ":right"
            #   end
            #   code << "    _b = #{children_variable}.text(#{value}.to_s, :left=>#{pt_to_s(column[:offset]+cell_margin[3])}, :top=>#{pt_to_s(cell_margin[0])}, :width=>#{pt_to_s(column[:width]-cell_margin[1]-cell_margin[3])}, :align=>:#{column[:align]})\n"
            #   code << "    row_height = _b.height if _b.height > row_height\n"
            # end
            # code << "    row_height += #{pt_to_s(cell_margin[0]+cell_margin[2])}\n"
            # for column in columns
            #   code << "    #{children_variable}.line([#{pt_to_s(column[:offset])}, 0], [#{pt_to_s(column[:offset])}, row_height], :stroke=>#{stroke})\n"
            # end
            # code << "    #{children_variable}.line([#{pt_to_s(start)}, 0], [#{pt_to_s(offset)}, 0], [#{pt_to_s(offset)}, row_height], [#{pt_to_s(start)}, row_height], :stroke=>#{stroke})\n"
            # code << "  end\n"
            # code << "end\n"


          elsif name == :text
            options = parameters_values(element)
            options[:align] ||= :left
            if right = options.delete(:right)
              options[:left] = "(#{variable}.current_box.width - #{pt_to_s(right)})"
            else
              options[:left] ||= 0
            end
            if options[:align] == :right and options[:width]
              options[:left] = "(#{options[:left]} - #{pt_to_s(options[:width])})"
            elsif options[:align] == :right and !options[:width]
              if options[:left].is_a?(Numeric) and options[:left] > 0
                options[:width] = options[:left]
              elsif options[:left].is_a?(String)
                options[:width] = options[:left]
              end
              options[:left] = 0
            elsif options[:align] == :center and options[:width]
              options[:left] = "(#{options[:left]} - #{pt_to_s(options[:width]/2)})"
            elsif options[:align] == :center and !options[:width]
              if options[:left].is_a?(Numeric) and options[:left] > 0
                options[:width] = options[:left]*2
              elsif options[:left].is_a?(String)
                options[:width] = "(#{options[:left]}*2)"
              end
              options[:left] = 0
            end
            if font = options[:font]
              font = "Helvetica" if font.downcase == "helvetica"
              font = "Times-Roman" if font.downcase == "times"
              phash[:font] = "'#{font}'"
            end
            phash[:left] = options[:left]
            phash[:width] = options[:width] if options[:width]
            phash.delete(:right)
            value = phash.delete(:value) || phash.delete(:content)
            code << "#{variable}.text(#{value}, #{hash_to_code(phash, true)})"

          else
            raise Exception.new("Unknown element '#{name}'")
          end


          # Wrapper: font
          if element.attributes['font']
            # code = "#{variable}.font('#{element.attributes['font']}') do\n#{code.strip.gsub(/^/,'  ')}\nend"
          end

          # Wrapper: if <condition>
          if element.attributes['if'] and @mode != :debug
            code = "if #{element.attributes['if'].to_s.gsub(/\//,'.')}\n#{code.strip.gsub(/^/,'  ')}\nend"
          end
          return code.strip
        end

      end
    end
  end
end
