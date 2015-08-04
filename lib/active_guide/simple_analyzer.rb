module ActiveGuide
  class SimpleAnalyzer
    class Env
      attr_accessor :variables, :results, :answer, :verbose

      def initialize(verbose = true)
        @variables = OpenStruct.new
        @results = OpenStruct.new
        @answer = nil
        @verbose = verbose
      end
    end

    def run(guide, options = {})
      env = Env.new
      env.verbose = !options[:verbose].is_a?(FalseClass)
      puts 'Running...'.yellow if env.verbose
      results = analyze_item(guide.root, env, -1)
      if env.verbose
        puts "#{results[:failed].to_s.red} tests failed, #{results[:passed].to_s.green} tests passed"
        env.results.to_h.each do |name, _r|
          puts " > #{name.to_s.humanize}: #{env.variables.send(name).to_s.yellow}"
        end
      end
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
      results = { failed: 0, passed: 0 }
      log_group(env, group.name, depth)
      call_callbacks(group, env) do
        group.items.each do |item|
          r = analyze_item(item, env, depth + 1)
          results[:failed] += r[:failed]
          results[:passed] += r[:passed]
        end
      end
      results
    end

    def analyze_test(test, env, depth = 0)
      results = { failed: 0, passed: 0 }
      call_callbacks(test, env) do
        if test.validate?
          if r = !!env.instance_exec(&test.validate_block)
            results[:passed] += 1
          else
            results[:failed] += 1
          end
          log_result(env, test.name, r, depth)
        else
          failed = 0
          test.subtests.each do |subtest|
            r = analyze_test(subtest, env, depth + 1)
            failed += 1 if r[:failed] > 0
          end
          if r = failed.zero?
            results[:passed] += 1
          else
            results[:failed] += 1
          end
          log_result(env, test.name, r, depth)
        end
      end
      results
    end

    def analyze_question(question, env, depth)
      results = { failed: 0, passed: 0 }
      call_callbacks(question, env) do
        if r = rand > 0.5
          results[:passed] += 1
        else
          results[:failed] += 1
        end
        log_result(env, "#{question.name.to_s.humanize} ?", r, depth)
      end
      results
    end

    def analyze_result(result, env)
      env.results[result.name] = result
      { failed: 0, passed: 0 }
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
        puts "#{(prefix + message.to_s.humanize).yellow}"
      end
    end
  end
end
