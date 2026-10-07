# frozen_string_literal: true

class Components::CategoryForm < Components::Base
  include Phlex::Rails::Helpers::FormAuthenticityToken

  # @param parents [Enumerable<Category>, nil] the roots a new category may hang
  #   from; nil on an edit, where neither the parent nor the nature can change
  def initialize(category:, action:, parents: nil, method: nil)
    @category = category
    @action = action
    @parents = parents
    @method = method
  end

  def view_template
    RubyUI.Form(action: @action, method: "post", class: "flex flex-col gap-4") do
      input(type: "hidden", name: "authenticity_token", value: form_authenticity_token)
      input(type: "hidden", name: "_method", value: @method) if @method

      render Components::Field.new(
        name: :name, label: Category.human_attribute_name(:name), model: @category, scope: "category"
      )
      nature_and_parent_fields if @parents
      color_field
      icon_field
      preview

      div(class: "flex items-center gap-3") do
        RubyUI.Button(type: "submit") { t(".submit") }
        RubyUI.Link(href: categories_path) { t(".cancel") }
      end
    end
  end

  private

  def nature_and_parent_fields
    render Components::SelectField.new(
      name: :nature, label: Category.human_attribute_name(:nature), scope: "category",
      model: @category, hint: t(".nature_hint"),
      options: Category.natures_in_order.map { |nature| [ nature, Category.human_nature(nature) ] }
    )

    render Components::SelectField.new(
      name: :parent_id, label: Category.human_attribute_name(:parent_id), scope: "category",
      model: @category, hint: t(".parent_hint"),
      options: [ [ "", t(".parent_none") ] ] + @parents.map { |parent| [ parent.id, parent.name ] }
    )
  end

  def color_field
    render Components::SelectField.new(
      name: :color, label: Category.human_attribute_name(:color), scope: "category",
      model: @category,
      options: Category::COLORS.keys.map { |color| [ color, Category.human_color(color) ] }
    )
  end

  def icon_field
    render Components::SelectField.new(
      name: :icon, label: Category.human_attribute_name(:icon), scope: "category",
      model: @category,
      options: Category::ICONS.map { |icon| [ icon, Category.human_icon(icon) ] }
    )
  end

  # Nothing to preview while the chosen colour or icon was rejected: the badge
  # would have no classes to wear.
  def preview
    return if @category.name.blank?
    return if @category.errors[:color].any? || @category.errors[:icon].any?

    RubyUI.FormField do
      RubyUI.FormFieldLabel { t(".preview") }
      div { render Components::CategoryBadge.new(@category) }
    end
  end
end
