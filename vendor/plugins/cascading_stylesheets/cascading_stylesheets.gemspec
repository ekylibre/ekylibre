Gem::Specification.new do |s|
  s.name     = "cascading_stylesheets"
  s.version  = "2.0.1"
  s.date     = "2009-01-14"
  s.summary  = "Include controller and action specific stylesheet files in your Ruby on Rails templates."
  s.email    = "haruki.zaemon@gmail.com"
  s.homepage = "http://github.com/harukizaemon/cascading_stylesheets"
  s.description = "Cascading Stylesheets is a Ruby on Rails plugin that enhances the behaviour of the built-in stylesheet_link_tag macro to include controller and action specific stylesheet files."
  s.has_rdoc = true
  s.authors  = ["Simon Harris"]
  s.files    = ["CHANGELOG.rdoc",
                "MIT-LICENSE",
                "README.rdoc",
                "cascading_stylesheets.gemspec",
                "lib/cascading_stylesheets.rb",
                "lib/haruki_zaemon/cascading_stylesheets/action_view/helpers/asset_tag_helper.rb"]
  s.rdoc_options = ["--main", "README.rdoc"]
  s.extra_rdoc_files = ["CHANGELOG.rdoc", "README.rdoc"]
end
