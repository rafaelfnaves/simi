# frozen_string_literal: true

# Bridges RubyUI's form primitives to Active Model errors, so every form in the
# product labels, fills and reports a field the same way.
class Components::Field < Components::Base
  def initialize(name:, label:, model: nil, scope: nil, type: :text, value: nil, **attrs)
    @name = name
    @label = label
    @model = model
    @scope = scope
    @type = type
    @value = value
    @attrs = attrs
  end

  def view_template
    RubyUI.FormField do
      RubyUI.FormFieldLabel(for: id) { @label }
      RubyUI.Input(type: @type, id:, name: qualified_name, value: current_value, **@attrs)
      RubyUI.FormFieldError { errors.to_sentence } if errors.any?
    end
  end

  private

  def qualified_name = @scope ? "#{@scope}[#{@name}]" : @name.to_s

  def id = qualified_name.tr("[", "_").delete("]")

  def current_value
    return @value unless @value.nil?
    return nil if @type == :password

    @model&.public_send(@name)
  end

  def errors = @model&.errors&.[](@name) || []
end
