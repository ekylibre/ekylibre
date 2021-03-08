# == License
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2015 Brice Texier
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
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

module Backend
  module KujakuHelper
    # Kujaku 孔雀
    # Search bar
    def kujaku(*args)
      options = args.extract_options!
      url = options[:url] || {}
      name = args.shift || ("#{controller_path}-#{action_name}-" + caller.first.split(/\:/).second).parameterize
      k = Kujaku.new(self, name)
      if block_given?
        yield k
      else
        k.text
      end
      return '' unless k.feathers.any?

      collapsed = current_user.preference("interface.kujakus.#{k.uid}.collapsed", (options.key?(:collapsed) ? !!options[:collapsed] : true), :boolean).value
      render('backend/shared/kujaku', kujaku: k, url: url, collapsed: collapsed, with_form: !options[:form].is_a?(FalseClass), with_actions: !options[:actions].is_a?(FalseClass))
    end

    class Kujaku
      # Hane means "feather". It designs a criterion
      class Feather
        class << self
          def inherited(subclass)
            class_name = subclass.name
            raise 'Invalid feather name' unless class_name =~ /Feather$/

            feather_name = class_name.gsub(/Feather$/, '').underscore.split('/').last.to_sym
            Kujaku.send(:define_method, feather_name) do |*args, &block|
              add_feather(subclass.new(self, "#{@uid}:#{@feathers.size}", *args, &block))
            end
          end

          def feather_name
            @feather_name ||= name.gsub(/Feather$/, '').underscore.split('/').last.to_sym
          end
        end

        attr_reader :uid

        def initialize(kujaku, uid, *args, &block)
          @kujaku = kujaku
          @uid = uid
          @template = kujaku.template
          @options = args.extract_options!
          @block = block if block_given?
          configure(*args)
        end

        def feather_name
          self.class.feather_name
        end

        def to_html
          @template.render("kujaku/feather/#{self.class.name.demodulize.underscore}", **vars)
        end

        def inspect
          "<#{self.class.name}##{@uid}>"
        end
      end

      # Text feather permits full text search
      class TextFeather < Feather
        def configure(*_args)
          @name = @options.delete(:name) || :q
        end

        def vars
          p = @template.current_user.pref("kujaku.feathers.#{@uid}.default", @template.params[@name])
          @template.params[@name] ||= p.value
          p.set!(@template.params[@name])

          {
            label: @options[:label] || :search.tl,
            name: @name,
            name_value: @template.params[@name],
            # This variable is not used in the associated partial
            preference: @template.current_user.pref("kujaku.feathers.#{@uid}.default", @template.params[@name])
          }
        end
      end

      class NumberFeather < Feather
        def configure(*_args)
          @name = @options.delete(:name) || :n
        end

        def vars
          {
            label: @options[:label] || :amount.tl,
            min_value: @template.params[:minimum_amount],
            max_value: @template.params[:maximum_amount]
          }
        end
      end

      class HiddenFeather < Feather
        def configure(*args)
          @name = @options.delete(:name) || args.shift || :n
        end

        def to_html
          @template.hidden_field_tag @name, @template.params[@name]
        end
      end

      # Choice feather permit to select one among many choice to filter
      class ChoiceFeather < Feather
        def configure(*args)
          @name = @options.delete(:name) || :s
          @choices = args
        end

        def vars
          scope = @options[:scope] || [:labels]
          # @type [Arrray<Array{String, String}>] choices
          choices = @choices.map do |choice|
            if choice.is_a?(Array)
              choice
            else
              [::I18n.translate(choice, scope: scope), choice]
            end
          end
          {
            label: @options[:label] || :state.tl,
            name: @name,
            # This variable is not used in the associated partial
            default_value: @template.params[@name],
            choices: choices
          }
        end
      end

      # Multi choice feather permits to select multiple choice in a list
      class MultiChoiceFeather < Feather
        def configure(*args)
          if args.last.is_a?(Array)
            ActiveSupport::Deprecation.warn("Please use an array of hash named 'data' instead of an anonymous array of array : Refer to intervention index view for an example")
            choices = args.delete_at(-1)
            @choices = choices.map do |choice|
              {
                label: choice[0],
                name: choice[1]
              }
            end
          elsif @options[:data]
            @choices = @options[:data]
          else
            raise 'You need to pass a data argument'
          end

          @name = args.shift || @options.delete(:name) || :c

          preferences_and_default_values
        end

        def vars
          {
            name: @name,
            choices: @choices,
            label: @options[:label] || :state.tl
          }
        end

        private

          def preferences_and_default_values
            current_user = @template.current_user
            controller = @template.params[:controller]
            action = @template.params[:action]

            if @template.params[@name].nil?
              preference_value = []
              @choices.each do |choice|
                preference_name = "#{controller}##{action}.#{@name}_#{choice[:name]}"
                @template.params[@name] ||= []
                preference = current_user.preference(preference_name, nil, :boolean)
                choice[:checked] = preference.boolean_value
                preference_value << choice[:name].to_s if preference.boolean_value
              end
              @template.params[@name] = preference_value
            else
              @choices.each do |choice|
                preference_name = "#{controller}##{action}.#{@name}_#{choice[:name]}"
                is_checked = @template.params[@name].include?(choice[:name].to_s)
                choice[:checked] = is_checked
                current_user.prefer!(preference_name, is_checked, 'boolean')
              end
            end
          end
      end

      # Date search field
      class DateFeather < ChoiceFeather
        def configure(*args)
          @name = args.shift || @options.delete(:name) || :d
        end

        def vars
          {
            name: @name,
            label: @options[:label] || :select_date.tl,
            value: value = @template.params[@name]
          }
        end
      end

      # Maybe a duplicate of needle_choice, inspect this later
      class ListFeather < Feather
        def configure(*args)
          @name = (args.shift || @options.delete(:name) || :l).to_s
          @label = @options.delete(:label) || @name.tl
          @value_label = @options.delete(:value_label) || :name
          @list_values = @options.delete(:list_values)

          preferences_and_default_values
        end

        def vars
          list_values = [[]]
          if @list_values
            list_values += @list_values
          else
            list_values += @name.camelize.constantize.pluck(@value_label, :id).sort
          end

          {
            label: @label,
            select_tag_name: @name + '_id',
            list_values: list_values,
            default_value: @default_value
          }
        end

        private

          def preferences_and_default_values
            current_user = @template.current_user
            controller = @template.params[:controller]
            action = @template.params[:action]

            suffix_preference_name = @name + '_id'
            preference_name = "#{controller}##{action}.#{suffix_preference_name}"
            if @template.params[suffix_preference_name].nil?
              @template.params[suffix_preference_name] = current_user.preference(preference_name).value
            else
              current_user.prefer!(preference_name, @template.params[suffix_preference_name], 'string')
            end

            @default_value = @template.params[suffix_preference_name]
          end
      end

      # Custom search field based on rendering helper method
      class HelperFeather < Feather
        def configure(*args)
          args << @options
          if @block
          elsif @name = args.shift
            @args = args
          else
            raise ArgumentError.new('block or name is missing for helper feather')
          end
        end

        def to_html
          if @block
            @template.capture(&@block)
          else
            @template.send(@name, *@args)
          end
        end
      end

      class NavigationFeather < HelperFeather; end

      class PreviousNavigationFeather < NavigationFeather; end

      class NextNavigationFeather < NavigationFeather; end

      attr_reader :feathers, :template, :uid
      def initialize(template, uid)
        @template = template
        @uid = uid
        @feathers = []
      end

      def inspect
        "<#{self.class.name}##{@uid}>"
      end

      def visible_feathers
        # TODO: Improve
        feathers.reject { |f| f.class.name.demodulize =~ /^Hidden|PreviousNavigation|NextNavigation/ }
      end

      private

        def add_feather(feather)
          @feathers << feather
        end
    end
  end
end
