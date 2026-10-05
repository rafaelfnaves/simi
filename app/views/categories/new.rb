# frozen_string_literal: true

class Views::Categories::New < Views::Base
  def initialize(category:, parents:)
    @category = category
    @parents = parents
  end

  def view_template
    render Components::PageHeader.new(
      title: "Nova categoria",
      subtitle: "Despesa ou receita, com uma cor e um ícone para reconhecer de relance."
    )

    RubyUI.Card(class: "p-6 max-w-xl") do
      render Components::CategoryForm.new(
        category: @category, parents: @parents, action: categories_path
      )
    end
  end
end
