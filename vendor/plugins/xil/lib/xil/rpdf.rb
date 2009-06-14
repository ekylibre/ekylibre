module Xil

  class Engine

    def compile_rpdf
      "_set_controller_content_type(Mime::PDF);"+
        "doc=Hebi::Document.new;#{@template.source}\n;doc.generate;"
    end
    
  end

end
