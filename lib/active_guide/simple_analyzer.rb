module ActiveGuide
  class SimpleAnalyzer
    class Env
      attr_accessor :variables, :results, :answer, :verbose

      def initialize(verbose = true)
        @variables = OpenStruct.new
        @results = []
        @answer = nil
        @verbose = verbose
      end
    end

    def run(guide, options = {})
      started_at = Time.zone.now
      env = Env.new
      env.verbose = !options[:verbose].is_a?(FalseClass)
      puts 'Running...'.yellow if env.verbose
      report = analyze_item(guide.root, env, -1)
      # Adds results if any
      unless env.results.empty?
        report[:results] = []
        env.results.each do |result|
          report[:results] << { item: result.name, value: env.variables.send(result.name) }
        end
      end
      # Adds end time
      report[:started_at] = started_at
      report[:stopped_at] = Time.zone.now
      # Display report if wanted
      if env.verbose
        puts "#{report[:failed].to_s.red} tests failed, #{report[:passed].to_s.green} tests passed"
        report[:results].each do |r|
          puts " > #{r[:item].name.to_s.humanize}: #{r[:value].to_s.yellow}"
        end if report[:results]
      end
      report
    end

    def analyze_item(item, env, depth = 0)
      if item.is_a? ActiveGuide::Group
        return analyze_group(item, env, depth)
      elsif item.is_a? ActiveGuide::Test
        return analyze_test(item, env, depth)
      elsif item.is_a? ActiveGuide::Question
        return analyze_question(item, env, depth)
      elsif item.is_a? ActiveGuide::Result
        return analyze_result(item, env)
      else
        fail "Unknown item type: #{item.class.name}"
      end
    end

    def analyze_group(group, env, depth = 0)
      report = { failed: 0, passed: 0, points: [] }
      log_group(env, group.name, depth)
      call_callbacks(group, env) do
        group.items.each do |item|
          r = analyze_item(item, env, depth + 1)
          report[:failed] += r[:failed]
          report[:passed] += r[:passed]
          report[:points] += r[:points]
        end
      end
      report
    end

    def analyze_test(test, env, depth = 0)
      report = { failed: 0, passed: 0, points: [] }
      call_callbacks(test, env) do
        if test.validate?
          if r = !!env.instance_exec(&test.validate_block)
            report[:passed] += 1
          else
            report[:failed] += 1
          end
          report[:points] << { item: test.name, success: r }
          log_result(env, test.name, r, depth)
        else
          failed = 0
          subtests = []
          test.subtests.each do |subtest|
            r = analyze_test(subtest, env, depth + 1)
            rr = r[:failed]
            failed += 1 if rr > 0
            subtests << { item: test.name, success: rr }
          end
          if r = failed.zero?
            report[:passed] += 1
          else
            report[:failed] += 1
          end
          report[:points] << { item: test.name, success: r, subtests: subtests }
          log_result(env, test.name, r, depth)
        end
      end
      report
    end

    def analyze_question(question, env, depth)
      report = { failed: 0, passed: 0, points: [] }
      call_callbacks(question, env) do
        if (r = rand > 0.5)
          report[:passed] += 1
        else
          report[:failed] += 1
        end
        report[:points] << { item: question.name, success: r }
        log_result(env, "#{question.name.to_s.humanize} ?", r, depth)
      end
      report
    end

    def analyze_result(result, env)
      env.results << result
      { failed: 0, passed: 0, points: [] }
    end

    protected

    def call_callbacks(item, env, &_block)
      if item.accept_block
        return false unless env.instance_eval(&item.accept_block)
      end
      env.instance_eval(&item.before_block) if item.before_block
      env.answer = yield
      env.instance_eval(&item.after_block) if item.after_block
    end

    def log_result(env, message, passed, depth = 0)
      return unless env.verbose
      if depth >= 0
        prefix = '  ' * depth
        puts "#{(prefix + ' - ' + message.to_s.humanize).ljust(70).white} [#{passed ? '  OK  '.green : 'FAILED'.red}]"
      end
      passed
    end

    def log_group(env, message, depth = 0)
      return unless env.verbose
      if depth >= 0
        prefix = '  ' * depth
        puts (prefix + message.to_s.humanize).yellow.to_s
      end
    end
  end
end
