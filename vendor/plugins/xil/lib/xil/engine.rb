# require 'template'

module Xil


  class Engine
    def initialize(template)
      @template = template
      # @base = Xil::Base.new(@template.source)
    end

    def to_code

      code  = "_set_controller_content_type(Mime::PDF)\n"
      code += "'"+@template.filename+"'"
      code
    end

  end



end
