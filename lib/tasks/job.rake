require 'sidekiq/api'

namespace :job do
  task clear: :environment do
    Sidekiq::Queue.all.each do |queue|
      puts "Clear #{queue.name}"
      queue.clear
    end
    Sidekiq::RetrySet.new.clear
    Sidekiq::ScheduledSet.new.clear
  end

  task running: :environment do
    next false if Sidekiq::Stats.new.enqueued.zero?

    job_class = ENV['JOB_CLASS']
    job_tenant = ENV['TENANT']
    running = false
    Sidekiq::Queue.all.each do |queue|
      jobs = queue.entries.select do |entry|
        (!job_class || entry.item['args'].first['job_class'] == job_class) &&
          (!job_tenant || entry.item['apartment'] == job_tenant)
      end
      running ||= jobs.any?

      puts "\nMatching running jobs:" if jobs.any?
      jobs.sort_by(&:at).each do |entry|
        job = entry.item['args'].first['job_class']
        puts " - #{job} on #{entry.item['apartment']} on queue #{queue.name}"
      end
    end
    running
  end

  task done: :environment do
    job_class = ENV['JOB_CLASS']
    job_tenant = ENV['TENANT']
    Sidekiq::DeadSet.include Enumerable
    jobs = Sidekiq::DeadSet.new.select do |entry|
      (!job_class || entry.item['args'].first['job_class'] == job_class) &&
        (!job_tenant || entry.item['apartment'] == job_tenant)
    end
    puts "\nMatching jobs done:" if jobs.any?
    jobs.sort_by(&:at).each do |entry|
      job = entry.item['args'].first['job_class']
      print " - #{job} on #{entry.item['apartment']}\n     — Finished at #{entry.at}"
      if entry.error?
        error_class = entry.item["error_class"]
        error_message = entry.item["error_message"]
        puts " with error \"#{error_class}: #{error_message}\""
      else
        puts " without errors"
      end
    end.any?
  end

  desc "Displays all matching errored jobs"
  task errored: :environment do
    job_class = ENV['JOB_CLASS']
    job_tenant = ENV['TENANT']
    Sidekiq::DeadSet.include Enumerable
    jobs = Sidekiq::DeadSet.new.select do |entry|
      (!job_class || entry.item['args'].first['job_class'] == job_class) &&
        (!job_tenant || entry.item['apartment'] == job_tenant) &&
        entry.error?
    end

    puts "\nMatching errored jobs:" if jobs.any?
    jobs.sort_by(&:at).each do |entry|
      job = entry.item['args'].first['job_class']
      error_class = entry.item["error_class"]
      error_message = entry.item["error_message"]
      print " - #{job} on #{entry.item['apartment']}\n     — Finished at #{entry.at}"
      puts " with error \"#{error_class}: #{error_message}\""
    end.any?
  end

  desc "Displays all infos available for matching job (JOB_CLASS/TENANT)"
  task job_status: [:running, :done]

  task status: :environment do
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
