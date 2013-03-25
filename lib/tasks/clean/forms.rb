def check_symlink(view, ref, log, force = false)
  # puts "#{view} -> #{ref}"
  # return true
  count = 0
  if view.exist?
    if force
      FileUtils.rm_f(view)
      File.symlink(ref, view)
      count += 1
      log.write " - Force creation symlink #{view.to_s} -> #{ref}\n"
    elsif view.symlink?
      target = File.readlink(view)
      unless target.to_s == ref.to_s
        count += 1
        log.write " - #{view.to_s} is symlink poiting to #{target} but not to #{ref}\n"
      end
    else
      count += 1
      log.write " - #{view.to_s} is not a symlink(#{ref}) as expected\n"
    end
  else
    # Add symlink to
    File.symlink(ref, view)
    count += 1
    log.write " - Create symlink #{view.to_s} -> #{ref}\n"
  end
  return count
end

def check_view(view, haml, log)
  preamble  = "-# Generated automatically. Remove this line to keep your changes.\n"
  count = 0
  if view.exist?
    if view.file?
      f = File.open(view, "rb")
      source = f.read
      f.close
      if source.match(/^\-\# Generated/i)
        log.write " - Update view #{view.to_s}\n"
        File.open(view, "wb") do |f|
          f.write(preamble)
          f.write(haml)
        end
      else
        count += 1
        log.write " - Do not update view #{view.to_s} because not generated\n"
      end
    else
      count += 1
      log.write " - View #{view.to_s} is not a file\n"
    end
  else
    File.open(view, "wb") do |f|
      f.write(preamble)
      f.write(haml)
    end
    count += 1
    log.write " - Create view #{view.to_s}\n"
  end
  return count
end


# Browse all directories searching for _form.html.* and links missing views
task :forms => :environment do
  log = File.open(Rails.root.join("log", "clean-forms.log"), "wb")
  count = 0
  print " - Forms: "
  Dir.glob(Rails.root.join("app", "views", "**", "_form.html.*")) do |p|
    path = Pathname.new(p)
    # puts path.inspect

    dir = path.dirname

    steps = dir.relative_path_from(Rails.root.join("app", "views")).to_s.split(/\//)
    variable = (steps.size > 1 ? "[" +steps[0..-2].map{|ns| ":"+ns}.join(", ") + ", @#{steps[-1].singularize}]" : "@" + steps[0].singularize)
    # puts variable.inspect


    # puts dir.to_s
    new_view = Rails.root.join("app", "views", "forms", "new.html.haml").relative_path_from(dir)

    # Check new.html.haml
    code  = ""
    code << "=backend_form_for(#{variable}, (params[:dialog] ? {'data-dialog' => params[:dialog]} : {})) do |f|\n"
    code << "  -if params[:redirect]\n"
    code << "    =hidden_field_tag(:redirect, params[:redirect])\n"
    code << "  .form-fields>=render(:partial => 'form', :locals => {:f => f})\n"
    code << "  =form_actions do\n"
    code << "    =submit_tag(tl(:create), 'data-disable-with' => tl(:please_wait))\n"
    # code << "    =link_to(tl(:cancel), :back, (params[:dialog] ? {'data-close-dialog' => params[:dialog]} : {}))\n"
    code << "    =link_to(tl(:cancel), #{steps.join('_')}_url, (params[:dialog] ? {'data-close-dialog' => params[:dialog]} : {}))\n"

    count += check_view(dir.join("new.html.haml"), code, log)
    # count += check_symlink(dir.join("new.html.haml"), new_view, log)

    # Check create.html.haml
    count += check_symlink(dir.join("create.html.haml"), "new.html.haml", log, true)

    edit_view = Rails.root.join("app", "views", "forms", "edit.html.haml").relative_path_from(dir)

    cancel = if dir.join("show.html.haml").exist?
               (steps.size > 1 ? steps[0..-2].join("_") + "_#{steps[-1].singularize}" : steps[0].singularize) + "_url(@#{steps[-1].singularize})"
             else
               "#{steps.join('_')}_url"
             end

    code  = ""
    code << "=backend_form_for(#{variable}, (params[:dialog] ? {'data-dialog' => params[:dialog]} : {})) do |f|\n"
    code << "  -if params[:redirect]\n"
    code << "    =hidden_field_tag(:redirect, params[:redirect])\n"
    code << "  .form-fields>=render(:partial => 'form', :locals => {:f => f})\n"
    code << "  =form_actions do\n"
    code << "    =submit_tag(tl(:update), 'data-disable-with' => tl(:please_wait))\n"
    # code << "    =link_to(tl(:cancel), :back, (params[:dialog] ? {'data-close-dialog' => params[:dialog]} : {}))\n"
    code << "    =link_to(tl(:cancel), #{cancel}, (params[:dialog] ? {'data-close-dialog' => params[:dialog]} : {}))\n"


    # Check edit.html.haml
    count += check_view(dir.join("edit.html.haml"), code, log)
    # count += check_symlink(dir.join("edit.html.haml"), edit_view, log)

    # Check update.html.haml
    count += check_symlink(dir.join("update.html.haml"), "edit.html.haml", log, true)
  end
  puts " #{count} warnings"
  log.close
end
