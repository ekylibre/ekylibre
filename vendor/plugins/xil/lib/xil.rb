require 'measure'
#require File.dirname(__FILE__)+'/xil/style'
#require File.dirname(__FILE__)+'/xil/base'
#require File.dirname(__FILE__)+'/xil/pdf'

module Xil
  mattr_accessor :options

  @@options={:features=>[], :documents_path=>"#{RAILS_ROOT}/private/documents", :subdir_size=>4096, :document_model_name=>:documents, :template_model_name=>:templates, :company_variable=>:current_company, :crypt=>:rijndael}

#   module ActionController
#     def self.included (base)
#       base.extend(ClassMethods)
#     end

#     module ClassMethods
#       require 'rexml/document'
#       require 'digest/md5'
#       require 'ebi'
#       require 'hebi'
#       include REXML
#     end


#     def render_xil(xil, options={})
#       options = {:output=>:pdf}.merge(options)
#       template = Xil::Template.new(xil)
#       method = template.method_name(options[:output])
#       code = '[NoCode]'
#       unless self.methods.include? method
#         code = template.compile_for(options[:output])
#         puts code
#         class_eval(code)
#       end
#       self.send(method, options)
#     end

#   end



  class TemplateHandler < ActionView::TemplateHandler
    include ActionView::TemplateHandlers::Compilable if defined?(ActionView::TemplateHandlers::Compilable)

    def initialize(view=nil)
      @view = view
    end

    def call(template)
      # compile(template)
      template.inspect
      "Toto 2"
    end

    def render(template, local_assigns = {})
      "Toto"
    end

    def compile(template)
      #options = Xil::Template.options.dup
      options = {}

      # template is a template object in Rails >=2.1.0,
      # a source string previously
#       if template.respond_to? :source
#         options[:filename] = template.filename
#         source = template.source
#       else
#         source = template
#       end

      # Haml::Engine.new(source, options).send(:precompiled_with_ambles, [])
      puts template.inspect
      send_data "ABC", :type=>'text/raw'
    end

#    def cache_fragment(block, name = {}, options = nil)
#      @view.fragment_for(block, name, options) do
#        eval("_xilout.buffer", block.binding)
#      end
#    end
  end
end

if defined? ActionView::Template and ActionView::Template.respond_to? :register_template_handler
  ActionView::Template
else
  ActionView::Base
end.register_template_handler(:xil, Xil::TemplateHandler)

# ActionController::Base.send :include, Xil::ActionController
