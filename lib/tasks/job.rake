require 'sidekiq/api'

namespace :job do
  task :clear do
    Sidekiq::Queue.all.each do |queue|
      puts "Clear #{queue.name}"
      queue.clear
    end
    Sidekiq::RetrySet.new.clear
    Sidekiq::ScheduledSet.new.clear
  end

  task :status do
    puts 'Queues:'
    Sidekiq::Queue.all.each do |queue|
      puts " #{queue.name}:"
      queue.each do |job|
        puts "   #{job.jid}: #{job.klass}(#{job.args.map(&:inspect).join(', ')})"
      end
    end

    ps = Sidekiq::ProcessSet.new
    puts "#{ps.size} Processes:"
    ps.each do |process|
      puts " - #{process['hostname']}, Busy: #{process['busy']}, PID: #{process['pid']}"
    end

    workers = Sidekiq::Workers.new
    puts "#{workers.size} Workers:"
    workers.each do |process_id, thread_id, work|
      puts " - PID: #{process_id}, TID: #{thread_id}, #{work.inspect}"
      # process_id is a unique identifier per Sidekiq process
      # thread_id is a unique identifier per thread
      # work is a Hash which looks like:
      # { 'queue' => name, 'run_at' => timestamp, 'payload' => msg }
      # run_at is an epoch Integer.
      # payload is a Hash which looks like:
      # { 'retry' => true,
      #   'queue' => 'default',
      #   'class' => 'Redacted',
      #   'args' => [1, 2, 'foo'],
      #   'jid' => '80b1e7e46381a20c0c567285',
      #   'enqueued_at' => 1427811033.2067106 }
    end
  end
end

desc 'Show jobs status'
task job: 'job:status'
