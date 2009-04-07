module Ekylibre
  module Xil

    class Template

      def initialize(xil)
        @xil, @method_name = self.class.parse(xil)
      end
      
      def compile_for(output, method_name=nil)
        method = 'compile_for_'+output.to_s
        if self.methods.include? method
          code = (self.send 'compile_for_'+output.to_s, method_name)
        else
          raise Exception.new("Unknown output format: #{output.inspect}")
        end
        code
      end

      def method_name(output)
        method = @method_name+'_'+output.to_s
        if self.methods.include? method
          method
        else
          nil
        end
      end


      def self.parse(input)
        options = Ekylibre::Xil::ClassMethods::xil_options
        xil = nil
        method_name = nil
        if input.is_a? Integer
          # if the parameter is an integer.
          template = options[:template_model].find_by_id(input)
          raise Exception.new('This ID has not been found in the database.') if template.nil?
          method_name = input.to_s
          xil = template.content
        elsif input.is_a? String 
          # if the parameter is a string.
          # if it is a file. Else, an error is generated.
          if File.file? input
            file = File.open(input,'rb')
            xil = file.read.to_s
            file.close()
          end
          if input.start_with? '<?xml'
            # the string begins by the XML standard format.
            xil = input
          else
            raise Exception.new("It is not an XML data: "+input.inspect)
          end
          # encodage of string into a crypt MD5 format to easier the authentification of template by the XIL-plugin.
          method_name = Digest::MD5.hexdigest(xil)
          # the parameter is a template.
        elsif options[:features].include? :template
          if input.is_a? options[:template_model]
            xil = input.content
            method_name = input.id.to_s
          end
        end
        method_name = "render_xil_#{method_name}"
        xil, method_name
      end

    end



  end
end
