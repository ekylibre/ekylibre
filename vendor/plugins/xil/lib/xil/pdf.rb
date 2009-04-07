module Ekylibre
  module Xil

    class Template
      
      def compile_for_pdf(method_name=nil)
        method_name ||= self.method_name(:pdf)

        code  = "def #{method_name}(options={})\n"
        code += "  'test'\n"
        code += "end\n"
        
        code
      end

      private
      
      

    end

  end
end
