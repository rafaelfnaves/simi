# frozen_string_literal: true

class Components::MainNav < Components::Base
  include Phlex::Rails::Helpers::CurrentPage

  Item = Data.define(:label, :path) do
    def available? = path.present?
  end

  def view_template
    nav(aria_label: "Navegação principal") do
      RubyUI.SidebarMenu do
        items.each { |item| render_item(item) }
      end
    end
  end

  private

  def items
    [
      Item.new("Dashboard", root_path),
      Item.new("Transações", nil),
      Item.new("Contas", nil),
      Item.new("Cartões", nil),
      Item.new("Categorias", nil),
      Item.new("Configurações", settings_profile_path)
    ]
  end

  def render_item(item)
    RubyUI.SidebarMenuItem do
      if item.available?
        RubyUI.SidebarMenuButton(as: :a, href: item.path, active: current_page?(item.path)) do
          span { item.label }
        end
      else
        RubyUI.SidebarMenuButton(as: :span, aria_disabled: "true", class: "cursor-not-allowed opacity-50") do
          span { item.label }
          RubyUI.Badge(variant: :secondary, class: "ml-auto") { "Em breve" }
        end
      end
    end
  end
end
