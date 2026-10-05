# frozen_string_literal: true

class Views::Categories::Edit < Views::Base
  def initialize(category:)
    @category = category
  end

  def view_template
    render Components::PageHeader.new(
      title: "Editar categoria",
      subtitle: subtitle
    )

    RubyUI.Card(class: "p-6 max-w-xl") do
      render Components::CategoryForm.new(
        category: @category, action: category_path(@category), method: "patch"
      )
    end
  end

  private

  def subtitle
    nature = Category::NATURE_LABELS.fetch(@category.nature)
    @category.root? ? nature : "#{nature} · dentro de #{@category.parent.name}"
  end
end
