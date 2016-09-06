# = Informations
#
# == License
#
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2009 Brice Texier, Thibaud Merigon
# Copyright (C) 2010-2012 Brice Texier
# Copyright (C) 2012-2016 Brice Texier, David Joulin
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see http://www.gnu.org/licenses.
#
# == Table: calls
#
#  arguments        :jsonb
#  created_at       :datetime         not null
#  creator_id       :integer
#  id               :integer          not null, primary key
#  integration_name :string
#  lock_version     :integer          default(0), not null
#  name             :string
#  state            :string
#  updated_at       :datetime         not null
#  updater_id       :integer
#
class Call < Ekylibre::Record::Base
  # [VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates :integration_name, :name, :state, length: { maximum: 500 }, allow_blank: true
  # ]VALIDATORS]
  has_many :messages, class_name: 'CallMessage'
  has_many :requests, class_name: 'CallRequest'
  has_many :responses, class_name: 'CallResponse'

  # Sync
  def execute_now
    save!

    # Instantiate a ActionIntegration object with itself as parameter
    # to execute the api call.
    @response = integration.new(self).send(name.to_sym, *arguments)

    yield(self) if block_given?
  end
  alias execute execute_now

  # ASync
  # Not called #execute for risk users wouldn't notice the difference with
  # #execute_now and would call this one instead.
  def execute_async(&block)
    save!

    Thread.new do
      execute_now(&block)
      @state = :waiting
      @response = integration.new(self).send(name.to_sym, *arguments)
      @state = :done

      instance_exec(&block) if block_given?
    end
  end

  def integration
    integration_name.constantize
  end

  def success(code = nil)
    yield(result) if state_is?(:success) && state_code_matches?(code)
  end

  def error(code = nil)
    yield(result) if (state_is?(:error) || state_is?(:client_error) || state_is?(:server_error)) && state_code_matches?(code)
  end

  def client_error(code = nil)
    yield(result) if state_is?(:client_error) && state_code_matches?(code)
  end

  def server_error(code = nil)
    yield(result) if state_is?(:server_error) && state_code_matches?(code)
  end

  def redirect(code = nil)
    yield(result) if state_is?(:redirect) && state_code_matches?(code)
  end

  def on(code)
    yield(result) if state_code_matches?(code)
  end

  private

  def result
    @response.result
  end

  # Returns true for a nil/false code.
  def state_code_matches?(code)
    !code || state_code_is?(code)
  end

  def state_is?(state)
    @response.state.to_s.split('_').first == state.to_s
  end

  # Returns false for a nil/false code.
  def state_code_is?(state)
    @response.state.to_s.split('_')[1..-1].join('_') == state.to_s
  end
end
