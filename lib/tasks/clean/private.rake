namespace :clean do

  namespace :private do

    desc "Clean test files in private"
    task :test do
      dir = ENV["DIR"] || "private/test"
      `git clean -d -f -- #{dir}`
      `git checkout HEAD -- #{dir}`
    end

  end

  task :private => 'clean:private:test'

end
