json.id role.id
json.label role.name
xml_permissions = Nokogiri::XML::Builder.new do |xml|
  xml.send('uses-permissions'){
    role.uses_permissions.each{|name|
      xml.send('uses-permission', name: name)
    }
  }
end.to_xml.html_safe
json.permissions xml_permissions
