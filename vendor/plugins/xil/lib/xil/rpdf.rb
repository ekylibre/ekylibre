module Xil

  class Engine

    def compile_rpdf0
      "_set_controller_content_type(Mime::PDF);"+
        "doc=Hebi::Document.new;#{@template.source}\n;doc.generate;"
    end
    
    def compile_rpdf
      "_set_controller_content_type(Mime::PDF);"+
#        "_xil_compile_setup;"+
        "doc=Ibeh.document(Hebi::Document.new, self) do;#{@template.source}\n;end;doc.generate"
    end
    
  end

end
