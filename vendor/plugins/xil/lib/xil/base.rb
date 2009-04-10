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
        'template'=>{'document'=>1},
        'document'=>{'page'=>'+'},
        'page'=>{'block'=>'*'},
        'block'=>{'set'=>'+'},
        'set'=>{'text'=>'*'},
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
        code += "# #{element.name}\n"# if element.has_elements?
        environment[:depth] ||= 1
        element.each_element do |child|
          if XIL_MARKUP[element.name].keys.include? child.name
            env = environment.dup
            env[:depth] += 1
            #   code += "# <#{child.name}>\n"
            code += send(environment[:output].to_s+'_'+child.name, child, env)
          else
            code += "# Unknown child: #{child.name}\n"
          end
        end
        # code  = code.gsub(/\n(\ )*/, "\n").gsub(/(^\n|\n$)/,'').gsub(/^/,'\1'+"  "*environment[:depth])+"\n"
        code#.gsub("\n","\n"+"  "*environment[:depth])
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
