Rake::TaskManager.class_eval do
  def remove_task(task_name)
    @tasks.delete(task_name.to_s)
  end
end

def remove_task(task_name)
  Rake.application.remove_task(task_name)
end

namespace :test do

  desc "Run tests for lib sources"
  Rake::TestTask.new(:lib) do |t|    
    t.libs << "test"
    t.pattern = 'test/lib/**/*_test.rb'
    t.verbose = true    
  end

end

# lib_task = Rake::Task["test:lib"]
# test_task = Rake::Task[:test]
# test_task.enhance { lib_task.invoke }
remove_task("test")

task :test do
  errors = %w(test:units test:functionals test:integration test:lib).collect do |task|
    begin
      Rake::Task[task].invoke
      nil
    rescue => e
      task
    end
  end.compact
  abort "Errors running #{errors * ', '}!" if errors.any?
end
