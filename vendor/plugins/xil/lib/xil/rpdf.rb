module Xil

  class Engine
    
    def compile_rpdf
      # raise Exception.new [@template.instance_variables, @template].inspect
      code  = "_set_controller_content_type(Mime::PDF);"
      # code << "raise Exception.new(self.instance_variables.inspect);"
      code << "doc=Ibeh.document(Hebi::Document.new, self) do;#{@template.source}\n;end;pdf=doc.generate"
      code << ";@current_company.archive(@template, pdf);pdf"
      code
    end
    
  end

end
