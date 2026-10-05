# frozen_string_literal: true

# The select counterpart of Components::Field. RubyUI's Select is a scripted
# combobox; these are short, closed lists where the native control is enough.
class Components::SelectField < Components::Base
  CLASSES = "flex h-9 w-full rounded-md border border-border bg-background px-3 py-1 text-sm shadow-xs"

  # @param options [Array<Array(String, String)>] value and label pairs
  def initialize(name:, label:, options:, model: nil, scope: nil, selected: nil, hint: nil, **attrs)
    @name = name
    @label = label
    @options = options
    @model = model
    @scope = scope
    @selected = selected
    @hint = hint
    @attrs = attrs
  end

  def view_template
    RubyUI.FormField do
      RubyUI.FormFieldLabel(for: id) { @label }
      select(id:, name: qualified_name, class: CLASSES, **@attrs) do
        @options.each do |value, label|
          option(value: value, selected: value.to_s == current_value.to_s) { label }
        end
      end
      RubyUI.FormFieldHint { @hint } if @hint
      RubyUI.FormFieldError { errors.to_sentence } if errors.any?
    end
  end

  private

  def qualified_name = @scope ? "#{@scope}[#{@name}]" : @name.to_s

  def id = qualified_name.tr("[", "_").delete("]")

  def current_value
    return @selected unless @selected.nil?

    @model&.public_send(@name)
  end

  def errors = @model&.errors&.[](@name) || []
end
