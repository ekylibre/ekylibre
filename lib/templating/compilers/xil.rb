require 'templating/compilers/xil/support'
require 'templating/compilers/xil/xil20'

module Templating::Compilers
  module Xil

    # Main method which analyze version and use the best compiler
    def self.compile(string, options={})
      doc = ::LibXML::XML::Parser.string(string).parse
      version = doc.root["version"].to_s
      compiler = "Xil#{version.gsub(/\./, '')}"
      if Templating::Compilers::Xil.const_defined?(compiler)
        mod = Templating::Compilers::Xil.const_get(compiler)
        return mod.compile(doc, options={})
      else
        raise ArgumentError.new("Version #{version} of XIL is not supported")
      end
    end

  end
end
