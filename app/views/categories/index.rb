# frozen_string_literal: true

class Views::Categories::Index < Views::Base
  include Phlex::Rails::Helpers::ButtonTo

  def initialize(roots:, suggestible:)
    @roots = roots
    @suggestible = suggestible
  end

  def view_template
    render Components::PageHeader.new(title: t(".title"), subtitle: t(".subtitle")) do
      RubyUI.Button(as: :a, href: new_category_path) { t(".new") }
    end

    return empty_state if @roots.none?

    div(class: "flex flex-col gap-4") do
      Category.natures_in_order.each { |nature| nature_card(nature) }
    end
  end

  private

  def empty_state
    RubyUI.Card(class: "p-6") do
      RubyUI.Empty do
        RubyUI.EmptyHeader do
          RubyUI.EmptyTitle { t(".empty_title") }
          RubyUI.EmptyDescription { t(".empty_description") }
        end

        RubyUI.EmptyContent(class: "flex flex-col items-center gap-2") do
          suggestion_form if @suggestible
          RubyUI.Link(href: new_category_path) { t(".suggest_decline") }
        end
      end
    end
  end

  def suggestion_form
    button_to t(".suggest"), categories_suggestions_path,
      class: "inline-flex h-9 items-center rounded-md bg-primary px-4 text-sm " \
             "font-medium text-primary-foreground"
  end

  def nature_card(nature)
    roots = @roots.select { |root| root.nature == nature }

    RubyUI.Card(class: "p-5 flex flex-col gap-4") do
      h2(class: "text-sm font-medium text-muted-foreground") do
        nature == "expense" ? t(".expenses") : t(".incomes")
      end

      if roots.any?
        ul(class: "flex flex-col gap-3") { roots.each { |root| root_item(root) } }
      else
        p(class: "text-sm text-muted-foreground") { t(".none_of_nature") }
      end
    end
  end

  def root_item(root)
    li(class: "flex flex-col gap-2") do
      row(root)

      subcategories = root.subcategories.sort_by { |sub| sub.name.downcase }
      if subcategories.any?
        ul(class: "flex flex-col gap-2 border-l border-border pl-4") do
          subcategories.each { |sub| li { row(sub) } }
        end
      end
    end
  end

  def row(category)
    div(class: "flex flex-wrap items-center justify-between gap-2") do
      div(class: "flex items-center gap-2") do
        render Components::CategoryBadge.new(category, class: ("opacity-60" if category.archived?))
        RubyUI.Badge(variant: :outline) { t(".archived") } if category.archived?
      end

      actions(category)
    end
  end

  def actions(category)
    div(class: "ml-auto flex flex-wrap items-center justify-end gap-x-3 gap-y-1") do
      if category.root? && category.active?
        RubyUI.Link(href: new_category_path(parent_id: category.id), class: "text-sm") do
          t(".new_subcategory")
        end
      end

      RubyUI.Link(href: edit_category_path(category), class: "text-sm") { t("actions.edit") }

      if category.archived?
        button_to t("actions.unarchive"), category_archive_path(category), method: :delete, class: link_classes
      else
        button_to t("actions.archive"), category_archive_path(category), class: link_classes
      end

      button_to t("actions.delete"), category_path(category), method: :delete, class: link_classes,
        form: { data: { turbo_confirm: t("confirm.delete", name: category.name) } }
    end
  end

  def link_classes = "text-sm underline underline-offset-4 hover:text-primary"
end
