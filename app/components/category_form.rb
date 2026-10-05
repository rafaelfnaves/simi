# frozen_string_literal: true

class Components::CategoryForm < Components::Base
  include Phlex::Rails::Helpers::FormAuthenticityToken

  COLOR_LABELS = {
    "slate" => "Cinza", "rose" => "Rosa", "orange" => "Laranja", "amber" => "Âmbar",
    "lime" => "Limão", "emerald" => "Verde", "teal" => "Turquesa", "sky" => "Azul",
    "violet" => "Violeta", "fuchsia" => "Magenta"
  }.freeze

  ICON_LABELS = {
    "home" => "Casa", "food" => "Alimentação", "car" => "Transporte", "health" => "Saúde",
    "education" => "Educação", "leisure" => "Lazer", "shopping" => "Compras",
    "receipt" => "Assinatura", "travel" => "Viagem", "work" => "Trabalho", "gift" => "Presente",
    "savings" => "Investimento", "wallet" => "Carteira", "other" => "Outro"
  }.freeze

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

      render Components::Field.new(name: :name, label: "Nome", model: @category, scope: "category")
      nature_and_parent_fields if @parents
      color_field
      icon_field
      preview

      div(class: "flex items-center gap-3") do
        RubyUI.Button(type: "submit") { "Salvar" }
        RubyUI.Link(href: categories_path) { "Cancelar" }
      end
    end
  end

  private

  def nature_and_parent_fields
    render Components::SelectField.new(
      name: :nature, label: "Natureza", scope: "category", model: @category,
      options: Category::NATURE_LABELS.to_a,
      hint: "Uma subcategoria herda a natureza da categoria-mãe."
    )

    render Components::SelectField.new(
      name: :parent_id, label: "Dentro de", scope: "category", model: @category,
      options: [ [ "", "Nenhuma — é uma categoria principal" ] ] + @parents.map { |p| [ p.id, p.name ] },
      hint: "Deixe em branco para criar uma categoria principal."
    )
  end

  def color_field
    render Components::SelectField.new(
      name: :color, label: "Cor", scope: "category", model: @category,
      options: Category::COLORS.keys.map { |color| [ color, COLOR_LABELS.fetch(color) ] }
    )
  end

  def icon_field
    render Components::SelectField.new(
      name: :icon, label: "Ícone", scope: "category", model: @category,
      options: Category::ICONS.map { |icon| [ icon, ICON_LABELS.fetch(icon) ] }
    )
  end

  # Nothing to preview while the chosen colour or icon was rejected: the badge
  # would have no classes to wear.
  def preview
    return if @category.name.blank?
    return if @category.errors[:color].any? || @category.errors[:icon].any?

    RubyUI.FormField do
      RubyUI.FormFieldLabel { "Como vai aparecer" }
      div { render Components::CategoryBadge.new(@category) }
    end
  end
end
