# plugin XIL : XML-based Impression-template Language.
# This module groups the different methods allowing to obtain a PDF document by the analyze of a template.
require File.dirname(__FILE__)+'/xil/style'
require File.dirname(__FILE__)+'/xil/base'
require File.dirname(__FILE__)+'/xil/pdf'


module Ekylibre
  module Xil

    def self.included (base)
      base.extend(ClassMethods)
    end

    module ClassMethods

      require 'rexml/document'
      require 'digest/md5'
      # require 'fpdf'
      # require 'pdf/writer'
      require 'spdf'

      include REXML

      # Array listing the main options used by XIL-plugin and specified here as a global variable.
      @@xil_options={:features=>[], :documents_path=>"#{RAILS_ROOT}/private/documents", :subdir_size=>4096, :document_model_name=>:documents, :template_model_name=>:templates, :company_variable=>:current_company, :crypt=>:rijndael}

      mattr_accessor :xil_options
    end
  end
end


# insertion of the module in the Actioncontroller
ActionController::Base.send :include, Ekylibre::Xil

ActionController::Base.class_eval do
  alias_method :render_without_xil, :render

  def render(options = {}, old_local_assigns = {}, &block) #:nodoc:
    if options.is_a?(Hash) && xil = options.delete(:xil)
      render_xil(xil, options[:params] || options)
    else
      render_without_xil(options, old_local_assigns, &block)
    end
  end


  def render_xil(xil, options={})
    options = {:output=>:pdf}.merge(options)
    template = Ekylibre::Xil::Template.new(xil)
    method = template.method_name(options[:output])
    code = '[NoCode]'
    unless self.methods.include? method
      code = template.compile_for(options[:output])
      puts code
      class_eval(code)
    end
    # Finally, the generated function is executed.
#    self.send(method, options[:key],options[:crypt]||xil_options[:crypt], options[:locals]||{})
    self.send(method, options) #[:key],options[:crypt]||xil_options[:crypt], options[:locals]||{})
#    send_data code, :disposition => 'inline'
    #render :text=>code
  end


  # this function looks for a method render_xil_name _'output' and calls analyse_template if not.
  def render_xil2(xil, options={})
    xil_options = Ekylibre::Xil::ClassMethods::xil_options
    options = {:output=>:pdf}.merge(options)

    template_options={:output=>options[:output]}
    template = nil
    if xil.is_a? Integer
      # if the parameter is an integer.
      template=xil_options[:template_model].find_by_id(xil)
      raise Exception.new('This ID has not been found in the database.') if template.nil?
      name=xil.to_s
      template=template.content
    elsif xil.is_a? String 
      # if the parameter is a string.
      # if it is a file. Else, an error is generated.
      if File.file? xil
        file=File.open(xil,'rb')
        xil=file.read.to_s
        file.close()
      end
      if xil.start_with? '<?xml'
        # the string begins by the XML standard format.
        template=xil
      else
        raise Exception.new("It is not an XML data: "+xil.to_s)
      end
      # encodage of string into a crypt MD5 format to easier the authentification of template by the XIL-plugin.
      name=Digest::MD5.hexdigest(xil)
      # the parameter is a template.
    elsif xil_options[:features].include? :template
      if xil.is_a? xil_options[:template_model]
        template=xil.content
        name=xil.id.to_s
      end
    end

    raise Exception.new("Type error on the parameter xil: "+xil.class.to_s) if template.nil?

    template_options[:name]=name

    # tests if the variable current_company is available.
    if xil_options[:features].include? :template  or xil_options[:features].include? :document
      current_company = instance_variable_get("@"+xil_options[:company_variable].to_s)
      raise Exception.new("No current_company.") if current_company.nil?
      template_options[:current_company]=xil_options[:company_variable]
    end

    method_name="render_xil_"+name+"_"+options[:output].to_s

    #the function which creates the PDF function is executed here.
    self.class.analyze_template(template, template_options) unless self.methods.include? method_name

    # Finally, the generated function is executed.
    self.send(method_name,options[:key],options[:crypt]||xil_options[:crypt], options[:locals]||{})
  end





  # this function initializes the whole necessary environment for Xil.
  def self.xil(options={})
    # runs all the name parameters passed to initialization and generate an error if it is undefined.
    options.each_key do |parameter|
      raise Exception.new("Unknown parameter : #{parameter}") unless Ekylibre::Xil::ClassMethods::xil_options.include? parameter
    end

    # Generate an exception if company_variable is initialized and with another value of current_company.
    unless options[:company_variable].nil?
      raise Exception.new("Company_variable must be equal to current_company.") unless options[:company_variable].to_s.eql? "current_company"
    end

    xil_options=Ekylibre::Xil::ClassMethods::xil_options.merge(options)
    new_options=xil_options

    # some verifications about the different arguments passed to the init function during the XIL-plugin initialization.
    raise Exception.new("Parameter crypt must be a symbol.") unless new_options[:crypt].is_a? Symbol
    raise Exception.new("Parameter subdir_size must be an integer.") unless new_options[:subdir_size].is_a? Integer
    raise Exception.new("Parameter impressions_path must be a string.") unless new_options[:documents_path].is_a? String
    raise Exception.new("Parameter features must be an array with maximaly two symbols.") unless new_options[:features].is_a? Array and new_options[:features].length<=2

    new_options[:features].detect do |element|
      unless element.is_a? Symbol
        raise Exception.new("The parameter features must be an array fulled with symbols.")
      end
    end

    # if a store of datas is implied by the user.
    if new_options[:features].include? :document
      if new_options[:document_model_name].is_a? Symbol
        new_options[:document_model]=new_options[:document_model_name].to_s.classify.constantize

        # the model of document specified by the user must contains particular fields.
        if ActiveRecord::Base.connection.tables.include? new_options[:document_model].table_name
          ["id", "filename","original_name","sha256","crypt_key","crypt_mode","company_id"].detect do |field|
            raise Exception.new("The table of document #{new_options[:document_model]} must contain at least the following field: "+field) unless new_options[:document_model].column_names.include? field
          end

          # if the impression of the PDF document is required, the function of saving document is generated.
          # it allows to encode the PDF document (considered as a data block) blocks by blocks with a specific
          # key randomly created and which is returned. The encryption algorithm used here is Rijndael.
          code=''
          code+="def self.save_document(mode,key,filename,binary,company_id)\n"
          code+="k=nil\n"
          code+="if mode==:rijndael\n"
          code+="k='+'*32\n"
          code+="32.times { |index| k[index]=rand(256) }\n"
          code+="end\n"

          code+="filesize=binary.length\n"
          code+="binary_digest=Digest::SHA256.hexdigest(binary)\n"
          code+="document=::"+new_options[:document_model].to_s+".create!(:key=>key,:filesize=>filesize,:sha256=>binary_digest, :original_name=>filename, :printed_at=>(Time.now), :crypt_key=>k, :crypt_mode=>mode.to_s,:company_id=>company_id,:filename=>'t')\n"
          code+="s='"+new_options[:documents_path]+"/'+(document.id/"+new_options[:subdir_size].to_s+").to_s+'/'\n"

          code+="Dir.mkdir(s) unless File.directory?(s)\n"
          code+="Ekylibre::Storage.encrypt_file(mode,s+document.id.to_s,k,binary)\n"

          code+="document.update_attribute(:filename,s+document.id.to_s)\n"

          code+="end\n"

          # concerning the function retrieve_document, it allows to decrypt a PDF document after retrieve it in
          # the database.
          code+="def self.retrieve_document(id)\n"
          code+="document=::"+new_options[:document_model].to_s+".find_by_id(id)\n"
          code+="raise Exception.new('Document has not been found in the database.') if document.nil?\n"

          code+="Ekylibre::Storage.decrypt_file(mode,document.filename,document.crypt_key)\n"

          code+="end\n"

          # in commentary, test the generate code putting it in a file.
          #f=File.open('test_save_and_retrieve.rb','wb')
          #f.write(code)
          #f.close

          module_eval(code)
        end

      else
        raise Exception.new("The name of document #{new_options[:document_model_name]} is not a symbol.")
      end

      # if the folder does not exist, an error is generated.
      unless File.directory?(new_options[:documents_path])
        raise Exception.new("Folder documents does not exist.")
      end
    end

    # if the user wishes to load a model to make the document (facture).
    if new_options[:features].include? :template
      if new_options[:template_model_name].is_a? Symbol
        new_options[:template_model]=new_options[:template_model_name].to_s.classify.constantize

        # the model of template specified by the user must contains particular fields.
        if ActiveRecord::Base.connection.tables.include? new_options[:template_model].table_name
          ["id", "content","cache","company_id"].detect do |field|
            raise Exception.new("The table of template #{new_options[:template_model]} must contains at least the following field: "+field) unless new_options[:template_model].column_names.include? field
          end
        end
      else
        raise Exception.new("The name of template #{new_options[:template_model_name]} does not a symbol.")
      end
    end

    Ekylibre::Xil::ClassMethods::xil_options=new_options

  end

end






