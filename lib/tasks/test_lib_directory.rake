namespace :test do

  desc "Run tests for lib sources"
  Rake::TestTask.new(:lib) do |t|    
    t.libs << "test"
    t.pattern = 'test/lib/**/*_test.rb'
    t.verbose = true    
  end

end

lib_task = Rake::Task["test:lib"]
test_task = Rake::Task[:test]
test_task.enhance { lib_task.invoke }
