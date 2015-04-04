namespace :clean do

  desc "Update and sort config/parts.xml"
  task :parts => :environment do
    print " - Parts: "
    menu_file = Rails.root.join("config", "parts.xml")

    # Read file
    doc = nil
    if File.exist?(menu_file)
      File.open(menu_file) do |f|
        doc = Nokogiri::XML(f) do |config|
          config.strict.nonet.noblanks
        end
      end
    else
      doc = Nokogiri::XML.new
      doc.root = Nokogiri::XML::Node.new('parts', doc)
    end

    # Removes undefined
    doc.xpath('//untreated-actions').remove

    ref = Clean::Support.actions_hash

    deleted = 0
    unused_actions = []
    for page in doc.xpath('//page')
      to = page.attr("to")
      url = to.to_s.strip.split("#")
      if ref[url[0]] and ref[url[0]].include?(url[1])
        page.remove_attribute('nonexistent')
        ref[url[0]].delete(url[1])
      else
        if ENV["FORCE"]
          page.remove
        else
          page['nonexistent'] = 'true'
        end
        deleted += 1
      end
    end

    undefined = Nokogiri::XML::Node.new('untreated-actions', doc)
    undefined_group = Nokogiri::XML::Node.new('group', doc)
    for controller, actions in ref.sort
      next unless actions.size > 0
      item = Nokogiri::XML::Node.new('item', doc)
      item['name'] = controller.to_s.split(/[\/]+/).last
      if first = actions.delete("index")
        page = Nokogiri::XML::Node.new('page', doc)
        page['to'] = "#{controller}##{first}"
        item.add_child(page)
        unused_actions << page['to']
      end
      for action in actions.sort
        page = Nokogiri::XML::Node.new('page', doc)
        page['to'] = "#{controller}##{action}"
        item.add_child(page)
        unused_actions << page['to']
      end
      undefined_group.add_child(item)
    end
    undefined.add_child(undefined_group)

    doc.root.add_child(undefined)
    File.open(menu_file, 'wb') do |f|
      f.write doc.to_s
    end
    print "#{unused_actions.size.to_s.rjust(3)} unused actions, #{deleted.to_s.rjust(3)} deletable actions\n"

  end

end
