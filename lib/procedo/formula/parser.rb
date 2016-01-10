module Procedo
  module Formula
    class Parser < Treetop::Runtime::CompiledParser
      include Procedo::Formula::Language
    end
  end
end
