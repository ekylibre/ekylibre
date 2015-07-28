module ActiveGuide

  class SimpleAnalyzer

    class Env
      attr_accessor :variables, :results

      def initialize
        @variables = OpenStruct.new
        @results = OpenStruct.new
      end
    end

    def run(guide)
      puts "Running...".yellow
      env = Env.new # binding
      results = analyze_item(guide.root, env)
      puts "#{results[:failed].to_s.red} tests failed, #{results[:passed].to_s.green} tests passed"
      env.results.to_h.each do |name, r|
        puts " > #{name.to_s.humanize}: #{env.variables.send(name).to_s.yellow}"
      end
    end

    def analyze_item(item, env)
      if item.is_a? ActiveGuide::Group
        return analyze_group(item, env)
      elsif item.is_a? ActiveGuide::Test
        return analyze_test(item, env)
      elsif item.is_a? ActiveGuide::Question
        return analyze_question(item, env)
      elsif item.is_a? ActiveGuide::Result
        return analyze_result(item, env)
      else
        raise "Unknown item type: #{item.class.name}"
      end
    end

    def analyze_group(group, env)
      results = {failed: 0, passed: 0}
      call_callbacks(group, env) do
        group.items.each do |item|
          r = analyze_item(item, env)
          results[:failed] += r[:failed]
          results[:passed] += r[:passed]
        end
      end
      return results
    end

    def analyze_test(test, env, depth = 0)
      results = {failed: 0, passed: 0}
      call_callbacks(test, env) do
        if test.validate?
          if r = !!env.instance_exec(&test.validate_block)
            results[:passed] += 1
          else
            results[:failed] += 1
          end
          log_result(test.name, r, depth)
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
          log_result(test.name, r, depth)
        end
      end
      return results
    end

    def analyze_question(question, env)
      results = {failed: 0, passed: 0}
      call_callbacks(question, env) do
        if r = rand > 0.5
          results[:passed] += 1
        else
          results[:failed] += 1
        end
        log_result("#{question.name.to_s.humanize} ?", r)
      end
      return results
    end

    def analyze_result(result, env)
      env.results[result.name] = result
      return {failed: 0, passed: 0}
    end

    protected

    def call_callbacks(item, env, &block)
      if item.accept_block
        return false unless env.instance_eval(&item.accept_block)
      end
      if item.before_block
        env.instance_eval(&item.before_block)
      end
      yield
      if item.after_block
        env.instance_eval(&item.after_block)
      end
    end

    def log_result(message, passed, depth = 0)
      prefix = "  " * depth
      if depth.zero?
        puts "#{(prefix + ' - ' + message.to_s.humanize).ljust(70).white} [#{passed ? '  OK  '.green : 'FAILED'.red}]"
      end
    end
    
  end

end
