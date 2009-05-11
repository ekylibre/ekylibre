module Ekylibre
  module Xil

    class Template


      XIL_MARKUP2 = {
        'template'=>{'document'=>1, 'styles'=>1},
        'styles'=>{'style'=>'+'},
        'style'=>{},
        'document'=>{'page'=>'+'},
        'page'=>{'loop'=>'*', 'block'=>'*', 'page-break'=>'*'},
        'loop'=>{'loop'=>'*', 'block'=>'*', 'page-break'=>'*'},
        'block'=>{'set'=>'+'},
        'set'=>{'text'=>'*', 'image'=>'*', 'rectangle'=>'*','line'=>'*'},
        'text'=>{},
        'image'=>{},
        'rectangle'=>{},
        'line'=>{},
        'page-break'=>{}
      }

      ORIENTATION={'portrait'=>'P', 'landscape'=>'L'}

      XIL_MARKUP = {
        'template'=>{:elements=>{'document'=>1, 'parameters'=>1}},
        'parameters'=>{:elements=>{'parameter'=>'*'}},
        'parameter'=>{},
        'document'=>{:elements=>{'page'=>'+'}},
        'page'=>{:elements=>{'loop'=>'*', 'block'=>'*'}},
        'loop'=>{:elements=>{'loop'=>'*', 'block'=>'*'}, :attributes=>{'for'=>:required, 'in'=>:required}},
        'block'=>{:elements=>{'set'=>'+'}},
        'set'=>{:elements=>{'text'=>'*', 'set'=>'*'}},
        'text'=>{},
      }


      def initialize(xil)
        @xil, @method_prefix = self.class.parse(xil)
        puts '@@ '+@method_prefix
      end
      
      def compile_for(output, method_name=nil)
        compile_method = 'compile_for_'+output.to_s
        if self.methods.include? compile_method
          method_name ||= self.method_name(output)
          code = self.send(compile_method, method_name, {:output=>output})
        else
          raise Exception.new("Unknown output format: #{output.inspect}")
        end
        code
      end

      def method_name(output)
        @method_prefix+'_'+output.to_s
      end

      private

      def browse(element, environment={})
        if XIL_MARKUP[element.name].nil?
          raise Exception.new('Unknown element: '+element.name)
        end


        code = ''
        #code += "# #{element.name}\n"# if element.has_elements?
        environment[:depth] ||= 1
        element.each_element do |child|
          #code += '#'+('  '*environment[:depth])+child.name.upper+"\n"
          if XIL_MARKUP[element.name][:elements].keys.include? child.name
            # Verification of the attributes
            raise Exception.new('Undefined element: '+child.name) if XIL_MARKUP[child.name].nil?
            (XIL_MARKUP[child.name][:attributes]||{}).each do |name, value|
              raise Exception.new("Attribute #{name.inspect} is missing for the element #{child.name}") if value==:required and child.attributes.get_attribute(name).nil?
            end

            env = environment.dup
            env[:depth] += 1
            code += send(environment[:output].to_s+'_'+child.name, child, env)
          #else
            #code += "# Unknown child: #{child.name}\n"
          end
        end
        # code  = code.gsub(/\n(\ )*/, "\n").gsub(/(^\n|\n$)/,'').gsub(/^/,'\1'+"  "*environment[:depth])+"\n"
        code#.gsub("\n","\n"+"  "*environment[:depth])
      end


      def string_clean(string, env={})
        string.gsub!("'","\\\\'")
        string.gsub!(/\{[^\}]+\}/) do |data|
          str = data[1..-2].strip
          if str =~ /\|/
            str = str.split('|')
            format = str[1]
            str = str[0]
          end
          if str =~ /CURRENT_DATETIME.*/
            format ||= "%Y-%m-%d %H:M"
            "'+#{env[:now]}.strftime('#{format}')+' "
          elsif str=~/TITLE/
            '\'+'+env[:title]+'.to_s+\''
          elsif str=~/PAGENO/
            '\'+'+env[:page_number]+'.to_s+\''
          elsif str=~/PAGENB/
            '@@PAGENB@@'
          elsif str=~/[a-z\_]{2,64}(\.[a-z\_]{2,64}){0,16}/
            # Add variable verification /variable.****/
            str += ".strftime('#{format}')" unless format.nil?
            "'+ic.iconv(#{str}.to_s)+'"
          else
            raise Exception.new('Unvalid string replacement: '+str)
          end
        end
        string = "'"+string+"'"
        string.gsub! /^\'\'\+/, ''
        string.gsub! /\+\'\'$/, ''
        # the string is converted to the format ISO, which is more efficient for the PDF softwares to read the
        # superfluous characters.
        Iconv.iconv('ISO-8859-15','UTF-8', string).to_s
      end


      def self.parse(input)
        options = Ekylibre::Xil::ClassMethods::xil_options
        xil_text = nil
        method_name = nil
        if input.is_a? Integer
          # if the parameter is an integer.
          template = options[:template_model].find_by_id(input)
          raise Exception.new('This ID has not been found in the database.') if template.nil?
          method_name = input.to_s
          xil_text = template.content
        elsif input.is_a? String 
          # if the parameter is a string.
          # if it is a file. Else, an error is generated.
          if File.file? input
            file = File.open(input,'rb')
            input = file.read.to_s
            file.close()
          end
          if input.start_with? '<?xml'
            # the string begins by the XML standard format.
            xil_text = input
          else
            raise Exception.new("It is not an XML data: "+input.inspect)
          end
          # encodage of string into a crypt MD5 format to easier the authentification of template by the XIL-plugin.
          method_name = Digest::MD5.hexdigest(xil_text)
          # the parameter is a template.
        elsif options[:features].include? :template
          if input.is_a? options[:template_model]
            xil_text = input.content
            method_name = input.id.to_s
          end
        end
        xil_tree = REXML::Document.new(xil_text)
        return xil_tree, "render_xil_#{method_name}"
      end

    end




  end
end
