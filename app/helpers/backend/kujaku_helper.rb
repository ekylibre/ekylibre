# coding: utf-8

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
      render('backend/shared/kujaku', kujaku: k, url: url, collapsed: collapsed, with_form: !options[:form].is_a?(FalseClass))
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
          raise NotImplementedError
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

        def to_html
          p = @template.current_user.pref("kujaku.feathers.#{@uid}.default", @template.params[@name])
          @template.params[@name] ||= p.value
          p.set!(@template.params[@name])
          html = @template.content_tag(:label, @options[:label] || :search.tl)
          html << ' '.html_safe
          html << @template.text_field_tag(@name, @template.params[@name])
          html
        end
      end

      class NumberFeather < Feather
        def configure(*_args)
          @name = @options.delete(:name) || :n
        end

        def to_html
          p = @template.current_user.pref("kujaku.feathers.#{@uid}.default", @template.params[@name])
          @template.params[@name] ||= p.value
          p.set!(@template.params[@name])
          html = @template.content_tag(:label, @options[:label] || :minimum_amount.tl)
          html << ' '.html_safe
          html << @template.number_field_tag('minimum_amount', @template.params[:minimum_amount], min: 0, step: :any)
          html << ' '.html_safe
          html << @template.content_tag(:label, @options[:label] || :maximum_amount.tl)
          html << ' '.html_safe
          html << @template.number_field_tag('maximum_amount', @template.params[:maximum_amount], min: 0, step: :any)
        end
      end

      # Choice feather permit to select one among many choice to filter
      class ChoiceFeather < Feather
        def configure(*args)
          @name = @options.delete(:name) || :s
          @choices = args
        end

        def to_html
          first = @choices.first
          @template.params[@name] ||= (first.is_a?(Array) ? first.first : first).to_s
          scope = @options[:scope] || [:labels]
          html = @template.content_tag(:label, @options[:label] || :state.tl)
          default_value = @template.params[@name]
          @choices.each do |choice|
            if choice.is_a?(Array)
              label = choice[0]
              value = choice[1]
            else
              label = ::I18n.translate(choice, scope: scope)
              value = choice
            end
            default_value ||= value.to_s
            html << @template.content_tag(:span, class: 'radio') do
              @template.content_tag(:label, for: "#{@name}_#{value}") do
                @template.radio_button_tag(@name, value, default_value.to_s == value.to_s) <<
                  ' '.html_safe <<
                  label
              end
            end
          end
          html
        end
      end

      # Multi choice feather permits to select multiple choice in a list
      class MultiChoiceFeather < Feather
        def configure(*args)
          @choices = args.last.is_a?(Array) ? args.delete_at(-1) : []
          @name = args.shift || @options.delete(:name) || :c
        end

        def to_html
          @template.params[@name] ||= []
          html = @template.content_tag(:label, @options[:label] || :state.tl)
          for human_name, choice in @choices
            html << @template.content_tag(:span, class: 'radio') do
              @template.content_tag(:label, for: "#{@name}_#{choice}") do
                @template.check_box_tag("#{@name}[]", choice, @template.params[@name].include?(choice.to_s), id: "#{@name}_#{choice}") <<
                  ' '.html_safe << human_name
              end
            end
          end
          html
        end
      end

      # Multi choice feather permits to select one choice in a long list
      # Like a "search a needle in hay"
      class NeedleChoiceFeather < ChoiceFeather
        def configure(*args)
          @selection = args.last.is_a?(Array) ? args.delete_at(-1) : []
          @name = args.shift || @options.delete(:name) || :o
        end

        def to_html
          @template.params[@name] ||= @selection.first.second if @selection && @selection.first
          html = @template.content_tag(:label, @options[:label] || :options.tl)
          html << ' '.html_safe
          html << @template.content_tag(:span, class: :slc) do
            @template.select_tag(@name, @template.options_for_select(@selection, @options[:selected] || @template.params[@name]))
          end
          html
        end
      end

      # Date search field
      class DateFeather < ChoiceFeather
        def configure(*args)
          @name = args.shift || @options.delete(:name) || :d
        end

        def to_html
          html = @template.content_tag(:label, @options[:label] || :select_date.tl)
          html << ' '.html_safe
          html << @template.date_field_tag(@name, @template.params[@name])
          html
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
            raise ArgumentError, 'block or name is missing for helper feather'
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

      attr_reader :feathers, :template, :uid
      def initialize(template, uid)
        @template = template
        @uid = uid
        @feathers = []
      end

      def inspect
        "<#{self.class.name}##{@uid}>"
      end

      private

      def add_feather(feather)
        @feathers << feather
      end
    end
  end
end
