module Procedures
  class Torrefactor

    attr_reader :variables, :compiled, :value_calls_count
    attr_accessor :value

    def initialize(options = {})
      @self  = options[:self]  || "self"
      @value = options[:value] || "value"
    end

    def compile(object)
      @variables = []
      @value_calls_count = 0
      @compiled = rewrite(object)
      return @compiled
    end

    protected

    def rewrite(object)
      if object.is_a?(Procedo::HandlerMethod::Expression)
        "(" + rewrite(object.expression) + ")"
      elsif object.is_a?(Procedo::HandlerMethod::Multiplication)
        rewrite(object.head) + " * " + rewrite(object.operand)
      elsif object.is_a?(Procedo::HandlerMethod::Division)
        rewrite(object.head) + " / " + rewrite(object.operand)
      elsif object.is_a?(Procedo::HandlerMethod::Addition)
        rewrite(object.head) + " + " + rewrite(object.operand)
      elsif object.is_a?(Procedo::HandlerMethod::Substraction)
        rewrite(object.head) + " - " + rewrite(object.operand)
      elsif object.is_a?(Procedo::HandlerMethod::Value)
        @value_calls_count += 1
        @value
      elsif object.is_a?(Procedo::HandlerMethod::Self)
        @self
      elsif object.is_a?(Procedo::HandlerMethod::Variable)
        @variables << object.text_value.to_sym
        object.text_value
      elsif object.is_a?(Procedo::HandlerMethod::Numeric)
        object.text_value.to_s
      elsif object.is_a?(Procedo::HandlerMethod::Reading)
        indicator = Nomen::Indicators[object.indicator.text_value]
        function = object.class.name.underscore.split('/').last.gsub('_reading', '').camelcase(:lower)
        parameters = ["'#{indicator.name}'"]
        unless [:decimal, :integer].include?(indicator.datatype)
          if object.respond_to?(:unit) and unit = Nomen::Units[object.unit.text_value]
            parameters << "'#{unit.name}'"
          else
            raise "Valid unit expected in #{object.inspect}"
          end
        end
        # "$.readings.#{function}(#{parameters.join(', ')})"
        "#{rewrite(object.actor)}.#{function}(#{parameters.join(', ')})"
      elsif object.nil?
        "null"
      else
        puts object.class.name.red
        # puts "(#{object.inspect})"
        # object.inspect
        # raise StandardError, "What ? #{object.inspect}"
        "(" + object.class.name + ")"
      end
    end

  end
end

namespace :procedures do

  task :precompile => :environment do
    file = Rails.root.join("app", "assets", "javascripts", "backend", "procedures.js.coffee")
    script = ""

    script << "# Generated with `rake procedures:precompile`.\n"
    script << "# Changes won't be kept after next compilation.\n\n"

    script << "(($) ->\n"
    script << "  'use strict'\n"

    events = ""


    script << "  $.handlers =\n"
    torrefactor = Procedures::Torrefactor.new
    for namespace, procedures in Procedo.procedures_tree
      next unless procedures.values.map(&:values).flatten.map(&:handled_variables).flatten.any?
      path = []
      path[0] = namespace.to_s.camelcase(:lower)
      ns_script  = "#{path[0]}:\n"
      for short_name, versions in procedures
        next unless versions.values.flatten.map(&:handled_variables).flatten.any?
        path[1] = short_name.to_s.camelcase(:lower)
        pr_script  = "#{path[1]}:\n"
        for version, procedure in versions
          path[2] = "v" + version.to_s.gsub(/\W/, '_').camelcase(:lower)
          vr_script  = "#{path[2]}:\n"
          for variable in procedure.handled_variables
            path[3] = variable.name.to_s.camelcase(:lower)
            va_script = "#{path[3]}:\n"
            for handler in variable.handlers
              path[4] = handler.name.to_s.camelcase(:lower)
              hn_script = "#{path[4]}:\n"

              events << "$(document).on 'keyup', 'input[data-variable-handler=\"#{handler.uid}\"]', -> $.handlers.#{path.join('.')}.updateOtherHandlers($(this))\n"
              # Updates other handlers
              torrefactor.value = "__value__"
              torrefactor.compile(handler.forward_tree)
              # Back to destination
              decls  = "# Declarations\n"
              decls << "__procedure__ = new $.Procedure('#{procedure.name}')\n"
              decls << "__value__ = "
              decls << if handler.datatype == :integer
                         "parseInt input.val()"
                       elsif handler.datatype == :string or handler.datatype == :choice
                         "input.val()"
                       else # otherwise float expected (decimal, measure)
                         "parseFloat input.val()"
                       end
              decls << " # #{handler.datatype.inspect}\n"
              decls << "self = __procedure__.actor('#{variable.name}')\n"
              local_variables = torrefactor.variables

              puts ("=" * 80).yellow
              # puts handler.forward_tree.inspect
              puts torrefactor.compiled.blue

              method  = "# Computations\n"
              method << "#{handler.destination} = #{torrefactor.compiled}\n"
              # Update destination
              method << "$('input[data-variable-destination=\"#{handler.destination_unique_name}\"]').val(#{handler.destination})\n"

              # Update others
              torrefactor.value = handler.destination.to_s
              for h in handler.others
                # Compute back calculus from destination to handler
                torrefactor.compile(h.backward_tree)
                local_variables += torrefactor.variables
                method << "$('input[data-variable-handler=\"#{h.uid}\"]').val(#{torrefactor.compiled})\n"
              end
              method << "true\n"

              for var in local_variables.uniq
                # if procedure.variables[var].new?
                #   raise "You cannot compute on not-created variables... #{var}"
                # end
                decls << "#{var} = __procedure__.actor('#{var}')\n"
              end

              hn_script << ("updateOtherHandlers: (input) ->\n" + decls.dig + method.dig).dig

              va_script << hn_script.dig
            end
            vr_script << va_script.dig
          end
          pr_script << vr_script.dig
        end
        ns_script << pr_script.dig
      end
      ns_script << "\n"
      script << ns_script.dig(2)
    end

    script << "  # Adds events on inputs\n"
    script <<  events.dig
    script << "\n"

    script << "  true\n"
    script << ") jQuery\n"

    FileUtils.mkdir_p(file.dirname)
    File.open(file, "wb") do |f|
      f.write script
    end
  end

end
