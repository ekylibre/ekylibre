module Procedures
  class MissingAttribute < StandardError
  end

  class MissingProcedure < StandardError
  end

  XMLNS = "http://www.ekylibre.org/XML/2013/procedures".freeze
  NS_SEPARATOR = "-"

  # This class represent a procedure
  class Procedure

    attr_reader :id, :name, :namespace, :operations, :parent, :position, :procedures, :variables, :version

    def initialize(element, options = {})
      name = element.attr("name").to_s.split(NS_SEPARATOR)
      if name.size == 2
        @namespace = name.shift.to_sym
      elsif name.size != 1
        raise ArgumentError.new("Bad name of procedure: #{element.attr("name").to_s.inspect}")
      end
      @name = name.shift.to_s.to_sym
      @required = (element.attr('required').to_s == "true" ? true : false)
      @parent = options[:parent] if options[:parent]
      @position = options[:position] || 0
      @id = element.attr("id").to_s
      raise MissingAttribute.new("Attribute 'id' must be given for a <procedure>") if @id.blank?
      @version = element.attr("version").to_s
      raise MissingAttribute.new("Attribute 'version' must be given for a <procedure>") if @version.blank?
      @variables = element.xpath("xmlns:variables/xmlns:variable").inject({}) do |hash, variable|
        hash[variable.attr("name").to_s] = Variable.new(self, variable)
        hash
      end
      @procedures = []
      element.xpath("xmlns:procedures/xmlns:procedure").each_with_index do |procedure, position|
        @procedures << Procedure.new(procedure, :parent => self, :position => position)
      end
      @operations = element.xpath("xmlns:operations/xmlns:operation").collect do |operation|
        Operation.new(self, operation)
      end
    end

    alias :children :procedures

    # Returns a fully-qualified name for the procedure
    def full_name
      (namespace ? namespace.to_s + NS_SEPARATOR + name.to_s : name.to_s)
    end

    # Returns if the procedure is required
    def required?
      @required
    end

    # Returns if the procedure is root
    def root?
      @parent.nil?
    end

    # Returns self with children recursively as an array
    def tree
      return procedures.inject([self]) do |array, procedure|
        array += procedure.tree
        array
      end
    end

    # Returns the full hash of procedured
    def hash
      return self.root.hash unless root?
      return self.tree.inject({}) do |hash, procedure|
        hash[procedure.id] = procedure
        hash
      end
    end

    # Returns the root procedure
    def root
      @root ||= (self.parent ? self.parent.root : self)
    end

    # Returns the next procedure from a given uid
    def followings_of(uid)
      p = self.hash[uid]
      raise ArgumentError.new("Unknown UID: #{uid.inspect}") unless p
      list = self.root.tree
      if i = list.index(p)
        return [] if (i + 1 == list.size)
        valids = []
        begin
          i += 1
          valids << list[i]
        end while !valids.last.required?
        return valids
      else
        raise StandardError.new("What???")
      end
    end

    # Return next sibling if exists
    def next_sibling
      @next_sibling ||= self.parent.children[self.position + 1]
    end

    # Return previous sibling if exist
    def previous_sibling
      return nil if self.position <= 0
      @next_sibling ||= self.parent.children[self.position - 1]
    end

    # Returns human_name of the procedure
    def human_name
      "procedures.#{name}".t(:default => ["labels.procedures.#{name}".to_sym, "labels.#{name}".to_sym, name.to_s.humanize])
    end

  end

  class Variable
    attr_reader :name, :procedure, :value, :abilities, :variety

    def initialize(procedure, element)
      @procedure = procedure
      @name = element.attr("name").to_sym
      @new = !element.attr("new").blank?
      @value = element.attr("value").to_s
      @abilities = element.attr("abilities").to_s
      @variety = element.attr("variety").to_s
    end

    def human_name
      "variables.#{name}".t(:default => ["labels.#{name}".to_sym, "attributes.#{name}".to_sym, name.to_s.humanize])
    end

    def given?
      !@value.blank?
    end

    def new?
      @new
    end

  end

  class Task
    attr_reader :expression, :operation

    def initialize(operation, element)
      @operation = operation
      @expression = element.attr("do")
    end

  end

  class Operation
    attr_reader :name, :procedure, :tasks

    def initialize(procedure, element)
      @procedure = procedure
      @name = element.attr("name").to_sym
      @tasks = element.xpath('xmlns:task').collect do |task|
        Task.new(self, task)
      end
    end
  end

  @@list = HashWithIndifferentAccess.new

  class << self

    # Returns the names of the procedures
    def names
      @@list.keys
    end

    # Give access to named procedures
    def [](name)
      @@list[name]
    end

    # Load all files
    def load
      browse_documents do |document|
        document.root.xpath('xmlns:procedure[@status="frozen"]').each do |procedure|
          name = procedure.attr("name").to_s
          n = Procedure.new(procedure)
          @@list[n.full_name] = n
        end
      end
    end

    # Import foreign procedures and build UID for each sub-procedures
    def flatten_sub_procedures(sps, prefix)
      document = sps.document
      procedures = Nokogiri::XML::Node.new "procedures", document
      for sp in sps.xpath('xmlns:sub-procedure')
        procedure = document.xpath("/xmlns:procedures/xmlns:procedure[@name='#{sp.attr('name')}']").first.clone
        for a in ['required', 'conditions']
          procedure[a] = sp.attr(a) if sp.has_attribute?(a)
        end
        for a in ['natures', 'status'] # 'version',
          procedure.remove_attribute(a) if procedure.has_attribute?(a)
        end

        unless sp.attr('id')
          raise StandardError.new('<sub-procedure> must have a unique id for the current procedure')
        end

        procedure['id'] = prefix + '-' + sp.attr('id').to_s + '-' + procedure.attr('name')

        if ssps = procedure.xpath('xmlns:sub-procedures').first
          flatten_sub_procedures(ssps, procedure.attr('id'))
        end

        for parameter in sp.xpath('xmlns:parameter')
          pname = parameter.attr('name').to_s
          parameter.attributes.keys

          variable = procedure.xpath("xmlns:variables/xmlns:variable[@name='#{pname}']").first
          raise "You can't use parameter #{pname} for procedure #{procedure.attr('name')}" unless variable
          other_attributes = ['variety', 'abilities', 'same-variety-of', 'same-nature-of']

          if !other_attributes.inject(1) { |m, a| m *= (parameter.has_attribute?(a) ? 0 : 1) }.zero? and variable['parameter'].to_s != 'false'
            variable['value'] = (parameter.has_attribute?('value') ? parameter.attr('value') : parameter.attr('name'))
            for a in other_attributes
              variable.remove_attribute(a)
            end
          elsif parameter.has_attribute?('value')
            raise StandardError.new("You can't use 'value' attribute in parameter with other attribute like 'variety' or 'abilities' or unwanted parameters")
          else
            for a in other_attributes
              variable[a] = parameter.attr(a) if parameter.has_attribute?(a)
            end
          end
        end
        procedures << procedure
      end
      sps.add_next_sibling(procedures)
      sps.remove
    end


    # Write one file per procedure after flattening
    def flatten
      FileUtils.mkdir_p(root)
      # Merge all procedures in one file
      builder = Nokogiri::XML::Builder.new do |xml|
        xml.procedures(:xmlns => XMLNS) {
          browse_documents(source) do |document|
            xml << document.root.xpath('xmlns:procedure[@status="frozen"]').to_xml.to_str
          end
        }
      end
      merger = Rails.root.join("tmp", "allinone.xml")
      File.open(merger, "wb") do |f|
        f.write builder.to_xml
      end
      source = nil
      f = File.open(merger, "rb")
      document = Nokogiri::XML(f) do |config|
        config.strict.nonet.noblanks.noent
      end
      f.close
      document.xpath('//comment()').remove
      # Clone and merge procedure recursively
      for p in document.xpath('/xmlns:procedures/xmlns:procedure')
        p['id'] = p.attr('name') unless p.has_attribute?('id')
        if sps = p.xpath('xmlns:sub-procedures').first
          flatten_sub_procedures(sps, p.attr('id'))
        end
      end

      # Write one file per procedure in root dir
      for procedure in document.xpath('/xmlns:procedures/xmlns:procedure')
        pname = procedure.attr('name')
        file = root.join(pname + ".xml")
        File.open(file, "wb") do |f|
          builder = Nokogiri::XML::Builder.new do |xml|
            xml.procedures(:xmlns => XMLNS) {
              xml << procedure.to_xml.to_str
            }
          end
          f.write builder.to_xml
        end
        f = File.open(file, "rb")
        document = Nokogiri::XML(f) do |config|
          config.strict.nonet.noblanks.noent
        end
        f.close
        File.open(file, "wb") do |f|
          f.write(document.to_s)
        end
      end
    end

    # Returns the root of the procedures
    def root
      Rails.root.join("config", "procedures")
    end

    def source
      Rails.root.join("config", "nomenclatures")
    end

    def browse_documents(dir = nil, &block)
      dir ||= root
      for path in Dir.glob(dir.join("*.xml"))
        f = File.open(path, "rb")
        document = Nokogiri::XML(f) do |config|
          config.strict.nonet.noblanks.noent
        end
        f.close
        # Add a better syntax check
        if document.root.namespace.href.to_s == XMLNS
          yield(document)
        else
          Rails.logger.info("File #{path} is not a procedure as defined by #{XMLNS}")
        end
      end
    end

  end

  # Load all procedures
  flatten
  load

  Rails.logger.info "Loaded procedures: " + names.to_sentence

end


