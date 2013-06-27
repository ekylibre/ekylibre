# encoding: utf-8
# ##### BEGIN LICENSE BLOCK #####
# Ekylibre - Simple ERP
# Copyright (C) 2009 Brice Texier, Thibaud Merigon
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
# ##### END LICENSE BLOCK #####

# encoding: utf-8

class Backend::FormBuilder < SimpleForm::FormBuilder

  # Display a selector with "new" button
  def referenced_association(association, options = {}, &block)
    reflection = find_association_reflection(association)
    raise "Association #{association.inspect} not found" unless reflection
    raise ArgumentError.new("Reflection #{reflection.name} must be a belongs_to") if reflection.macro != :belongs_to

    return self.association(association) if options[:field] == :hidden

    choices = options[:source] || {}
    choices = {:action => "unroll_#{choices.to_s}".to_sym} unless choices.is_a?(Hash)
    choices[:action] ||= :unroll
    choices[:controller] ||= reflection.class_name.underscore.pluralize

    new_url = {}
    new_url[:controller] ||= choices[:controller]
    new_url[:action] ||= :new

    model = @object.class
    input_id = model.name.underscore + "-" + association.to_s + "-input"

    return input(reflection.foreign_key, options.merge(:wrapper => :append, :reflection => reflection)) do
      self.input_field(reflection.foreign_key, 'data-selector' => @template.url_for(choices), :id => input_id, 'data-selector-new-item' => @template.url_for(new_url)) +
        # @template.link_to(('<span class="icon"></span><span class="text">' + @template.send(:h, 'labels.new'.t) + '</span>').html_safe, new_url, 'data-new-item' => input_id, :class => 'btn btn-new') +
        "".html_safe
    end
  end

  # Adds nested association support
  def nested_association(association, *args, &block)
    reflection = find_association_reflection(association)
    raise "Association #{association.inspect} not found" unless reflection
    ActiveSupport::Deprecation.warn "Nested association don't take code block anymore. Use partial '#{association.to_s.singularize}_fields' instead." if block_given?
    # raise ArgumentError.new("Reflection #{reflection.name} must be a has_many") if reflection.macro != :has_many
    item = association.to_s.singularize
    html = self.simple_fields_for(association) do |nested|
      @template.render("#{item}_fields", :f => nested)
    end
    if reflection.macro == :has_many
      html << @template.content_tag(:div, @template.link_to_add_association("labels.add_#{item}".t, self, association, 'data-no-turbolink' => true, :class => "nested-add add-#{item}"), :class => "links")
    end
    return @template.content_tag(:div, html, :id => "#{association}-field")
  end

  # Adds custom fields
  def custom_fields(*args, &block)
    custom_fields = @object.custom_fields
    if custom_fields.count > 0
      return @template.content_tag(:div, :id => "custom-fields-field") do
        html = "".html_safe
        for custom_field in custom_fields
          options = {:as => custom_field.nature.to_sym, :required => custom_field.required?, :label => custom_field.name}
          if custom_field.choice?
            options[:collection] = custom_field.choices.collect{|c| [c.name, c.value] }
          end
          html << self.input(custom_field.column_name, options)
        end
        html
      end
    end
    return nil
  end

  # Updates default input method
  def input(attribute_name, options = {}, &block)
    if targets = options.delete(:show)
      options[:input_html] ||= {}
      options[:input_html]["data-show"] = clean_targets(targets)
    end
    if targets = options.delete(:hide)
      options[:input_html] ||= {}
      options[:input_html]["data-hide"] = clean_targets(targets)
    end
    return super(attribute_name, options, &block)
  end


  # Load a partial
  def subset(name, options = {}, &block)
    options[:id] ||= name
    if options[:depend_on]
      options['data-depend-on'] = options.delete(:depend_on)
    end
    if block_given?
      return @template.content_tag(:div, capture(&block), options)
    else
      return @template.content_tag(:div, @template.render(:partial => "#{name}_form", :locals => {:f => self, :object => @object}), options)
    end
  end


  def backend_fields_for(*args, &block)
    options = args.extract_options!
    options[:wrapper] = self.options[:wrapper] if options[:wrapper].nil?
    options[:defaults] ||= self.options[:defaults]

    if self.class < ActionView::Helpers::FormBuilder
      options[:builder] ||= self.class
    else
      options[:builder] ||= Backend::FormBuilder
    end
    fields_for(*(args << options), &block)
  end

  protected

  def clean_targets(targets)
    if targets.is_a?(Symbol)
      return "##{targets}"
    elsif targets.is_a?(Array)
      return targets.collect{|t| clean_targets(t)}.join(", ")
    end
    return targets
  end

end


# This hack permits to change default presentation of the DateTime input
class SimpleForm::Inputs::DateTimeInput

  def input_html_options
    value = object.send(attribute_name)
    format = @options[:format] || :default
    raise ArgumentError.new("Option :format must be a Symbol referencing a translation 'date.formats.<format>'") unless format.is_a?(Symbol)
    if localized_value = value
      localized_value = I18n.localize(localized_value, :format => format)
    end
    format = I18n.translate('date.formats.'+format.to_s)
    Formize::DATE_FORMAT_TOKENS.each{|js, rb| format.gsub!(rb, js)}
    options = {
      "data-date" => format,
      "data-date-locale" => "i18n.iso2".t,
      "data-date-iso" => value,
      :value => localized_value,
      :size => @options.delete(:size) || 10
    }
    super.merge options
  end

  def input
    @builder.text_field(attribute_name, input_html_options)
  end

end
