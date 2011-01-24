# gem install -r fastercsv
# require 'fastercsv'
# gem install -r measure
# require 'measure'
# "Built-in" gems
require Rails.root.join("lib", "init")


# Load SCSS and SASS stylsheets in themes
for theme_dir in Dir[Rails.root.join("public", "themes", "*")]
  dir = File.join(theme_dir, "stylesheets")
  Sass::Plugin.add_template_location(dir, dir) if File.exist? dir
end
