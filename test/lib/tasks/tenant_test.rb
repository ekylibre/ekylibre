require 'test_helper'

module Ekylibre
  module Tasks
    class TenantTest < ActiveSupport::TestCase
      setup do
        @pseudo_env = PseudoEnvironment.new(self)
        @pseudo_env.set_to(:production)
        ENV['TENANT'] = 'my_awesome_tenant'
        Rake::Task.clear
        Ekylibre::Application.load_tasks
      end

      test 'restore shouldn\'t be possible in production env' do
        ENV['DANGEROUS_MODE'] = nil
        assert_raises Ekylibre::ForbiddenImport do
          Rake::Task['tenant:restore'].invoke
        end
      end

      test 'restore allowed if DANGEROUS_MODE is set but asks a ludicrous amount of confirmations' do
        ENV['DANGEROUS_MODE'] = 'on'
        @question_count = 0
        main = TOPLEVEL_BINDING.eval('self')
        main.stub :confirm, method(:confirm_and_count) do
          Ekylibre::Tenant.stub :restore, true do
            Ekylibre::Tenant.stub :exist?, true do
              without_output { Rake::Task['tenant:restore'].invoke }
            end
          end
        end

        assert_operator 3, :<=, @question_count
      end

      teardown do
        @pseudo_env.unset
      end

      def confirm_and_count(*_args)
        @question_count += 1
        true
      end
    end
  end
end
