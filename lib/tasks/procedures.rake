namespace :procedures do

  task :precompile => :environment do
    file = Rails.root.join("app", "assets", "javascripts", "backend", "procedures.js.coffee")
    script = ""

    script << "# Generated with `rake procedures:precompile`.\n"
    script << "# Changes won't be kept after next compilation.\n\n"

    script << "(($) ->\n"
    script << "  'use strict'\n"

    events = ""


    script << "  $.procedures =\n"
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

              events << "$(document).on 'keyup', 'input[data-variable-handler=\"#{handler.uid}\"]', -> $.procedures.#{path.join('.')}.updateOtherHandlers($(this))\n"
              # Updates other handlers
              method = "updateOtherHandlers: (input) ->\n"
              # Back to destination
              method << "  value = parseFloat(input.val())\n"
              puts handler.method_tree.inspect
              method << "  #{handler.destination} = value\n"
              # Update destination
              method << "  $('input[data-variable-destination=\"#{handler.destination_unique_name}\"]').val(#{handler.destination} * 3)\n"
              # Update others
              for h in handler.others
                method << "  $('input[data-variable-handler=\"#{h.uid}\"]').val(#{handler.destination} * #{2})\n"
              end
              method << "  true\n"

              hn_script << method.dig
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
