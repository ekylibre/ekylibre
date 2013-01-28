
desc "Build diagram with yuml.me"
task :diagram => :environment do
  list = if ActiveRecord::Base.respond_to? :descendants
           ActiveRecord::Base.send(:descendants)
         elsif ActiveRecord::Base.respond_to? :subclasses
           ActiveRecord::Base.send(:subclasses)
         else
           Object.subclasses_of(ActiveRecord::Base)
         end.select{|x| not x.name.match('::') and not x.abstract_class?}.uniq.sort{|a,b| a.name <=> b.name}
  
  yuml = '//Ekylibre'
  for model in list
    unless [ActiveRecord::Base, Ekylibre::Record::Base].include? model.superclass
      yuml << ",[#{model.name}]-^[#{model.superclass.name}]"
    end
    model.reflections.values.select{|r| r.macro == :belongs_to }.each_with_index do |reflection, index|
      yuml << ",[#{model.name}]1->*[#{reflection.class_name}]"
    end
  end
  yuml << ".png"

  uri = URI("http://yuml.me/diagram/class/")
  response = Net::HTTP.post_form(uri, :dsl_text => yuml)
  File.open("diagram.png", "wb") do |f|
    f.write response.body
  end
end
