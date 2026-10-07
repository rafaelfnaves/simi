# frozen_string_literal: true

class Views::Categories::New < Views::Base
  def initialize(category:, parents:)
    @category = category
    @parents = parents
  end

  def view_template
    render Components::PageHeader.new(title: t(".title"), subtitle: t(".subtitle"))

    RubyUI.Card(class: "p-6 max-w-xl") do
      render Components::CategoryForm.new(
        category: @category, parents: @parents, action: categories_path
      )
    end
  end
end
