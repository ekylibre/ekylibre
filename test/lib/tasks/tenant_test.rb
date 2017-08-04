require 'test_helper'

module Ekylibre
  module Tasks
    class TenantTest < ActiveSupport::TestCase
      setup do
        ENV['TENANT'] = 'my_awesome_tenant'

        @question_count = 0

        # Reload rake tasks so Rake doesn't ignore the `invoke`
        # thinking it's already been run.
        ::Rake::Task.clear
        Ekylibre::Application.load_tasks
      end

      test 'restore asks before overwriting existing tenants' do
        with_fully_mocked_restore tenant_exists: true do
          invoke_task('tenant:restore')
        end

        assert_operator @question_count, :>=, 1
      end

      test 'restore does not ask confirmation before overwriting if FORCE is set in env' do
        ENV['FORCE'] = '1'
        with_fully_mocked_restore tenant_exists: true do
          invoke_task('tenant:restore')
        end

        assert_equal 0, @question_count
        ENV['FORCE'] = nil
      end

      test 'restore shouldn\'t be possible in production env without DANGEROUS_MODE set' do
        PseudoEnvironment.new(self).set_to(:production) do
          ENV['DANGEROUS_MODE'] = nil
          assert_raises Ekylibre::ForbiddenImport do
            invoke_task('tenant:restore')
          end
        end
      end

      test 'when run in production restore confirms A LOT before overwriting existing tenants' do
        PseudoEnvironment.new(self).set_to(:production) do
          ENV['DANGEROUS_MODE'] = 'on'
          with_fully_mocked_restore tenant_exists: true do
            invoke_task('tenant:restore')
          end
        end

        assert_operator @question_count, :>=, 3
      end

      def confirm_and_count(*_args)
        @question_count += 1
        true
      end

      def with_fully_mocked_restore(tenant_exists:)
        main.stub :confirm, method(:confirm_and_count) do
          Ekylibre::Tenant.stub :restore, true do
            Ekylibre::Tenant.stub :exist?, tenant_exists do
              yield
            end
          end
        end
      end

      def invoke_task(task, with_output: false)
        task = ::Rake::Task[task]
        return task.invoke if with_output
        without_output { task.invoke }
      end
    end
  end
end
