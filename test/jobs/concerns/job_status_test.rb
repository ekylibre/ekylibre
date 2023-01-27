require 'test_helper'

class JobStatusTest < ActiveJob::TestCase
  # Uncomment when action cable becomes testable

  # class FakeJob < ApplicationJob
  #   include JobStatus

  #   def perform(user:); end
  # end

  # setup do
  #   @user = User.first
  # end

  # test 'It raise an error if user is not defined' do
  #   assert_raise ArgumentError do
  #     FakeJob.perform_later(user: nil)
  #   end
  # end

  # test 'after_enqueue callback' do
  #   FakeJob.perform_later(user: @user)
  #   assert Preference.get!('JobStatusTest::FakeJob_running'), 'It create job preference with true value'
  # end

  # test 'after_perform callback' do
  #   Preference.set!('JobStatusTest::FakeJob_running', true, :boolean)
  #   perform_enqueued_jobs do
  #     FakeJob.perform_now(user: @user)
  #   end
  #   assert_nil Preference.find_by(name: 'JobStatusTest::FakeJob_running'), 'It destroy job preference'
  # end

end
