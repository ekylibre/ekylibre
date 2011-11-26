require 'templating/compilers/xil/support'
require 'templating/compilers/xil/xil20'

module Templating::Compilers
  module Xil

    # Main method which analyze version and use the best compiler
    def self.compile(string, options={})
      doc = ::LibXML::XML::Parser.string(string).parse
      version = (doc.root["version"] || '2.0')
      compiler = "Xil#{version.gsub(/\./, '')}"
      if Templating::Compilers::Xil.const_defined?(compiler)
        klass = Templating::Compilers::Xil.const_get(compiler)
        raise compiler.inspect unless klass
        return klass.compile(doc, options)
      else
        raise ArgumentError.new("Version #{version} of XIL is not supported")
      end
    end

  end
end
