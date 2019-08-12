namespace :test do
  parts = [
    :concepts,
    :controllers,
    :exchangers,
    :helpers,
    :jobs,
    :lib,
    :models,
    :services,
    # misc
     :validators#, :decorators, :javascripts
  ]

  parts.each do |p|
    Rails::TestTask.new(p => 'test:prepare') do |t|
      t.libs = ['lib']
      t.pattern = "test/#{p}/**/*_test.rb"
    end
  end

  task all: parts #[*parts, :javascripts]
end
