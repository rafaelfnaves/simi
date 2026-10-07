# frozen_string_literal: true

class Views::Categories::Edit < Views::Base
  def initialize(category:)
    @category = category
  end

  def view_template
    render Components::PageHeader.new(title: t(".title"), subtitle: subtitle)

    RubyUI.Card(class: "p-6 max-w-xl") do
      render Components::CategoryForm.new(
        category: @category, action: category_path(@category), method: "patch"
      )
    end
  end

  private

  def subtitle
    return @category.human_nature if @category.root?

    t(".inside", nature: @category.human_nature, parent: @category.parent.name)
  end
end
