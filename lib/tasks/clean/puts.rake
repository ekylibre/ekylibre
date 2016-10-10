namespace :clean do
  task :puts do
    root = Pathname.new(__FILE__).expand_path.dirname.dirname.dirname.dirname
    Dir.glob("#{root}/**/exchangers/**/*.rb").each do |f|
      `sed -i -r 's/^(\\s+)puts\\b/\\1w.info/g' #{f}`
    end
    Dir.glob("#{root}/{app,db,config}/**/*.rb").each do |f|
      `sed -i -r 's/^(\\s+)puts\\b/\\1# puts/g' #{f}`
    end
  end
end
