#
# desc "Update SCM version in VERSION"
task :version => :environment do
  xml = `svn info --xml "#{Rails.root.to_s}"`
  doc = ActiveSupport::XmlMini.parse(xml)
  rev = doc['info']['entry']['commit']['revision'].to_i+1
  puts " - Current revision: #{rev}"
  code = ""
  File.open(Rails.root.join("VERSION"), "rb:UTF-8") do |f|
    code = f.read
  end
  code.gsub!(/,\d*\s*$/, ",#{rev}")
  File.open(Rails.root.join("VERSION"), "wb") do |f|
    f.write(code)
  end
end
