if defined? RubyProf
  module Ekylibre
    def self.profile(label, &block)
      result = RubyProf.profile(&block)
      printer = RubyProf::GraphHtmlPrinter.new(result)
      printer.print(File.open("tmp/#{label}.html", 'w'))
      printer = RubyProf::CallStackPrinter.new(result)
      printer.print(File.open("tmp/#{label}_stack.html", 'w'))
    end
  end
end
