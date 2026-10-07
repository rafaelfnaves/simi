# frozen_string_literal: true

class Components::MainNav < Components::Base
  include Phlex::Rails::Helpers::CurrentPage

  Item = Data.define(:label, :path) do
    def available? = path.present?
  end

  def view_template
    nav(aria_label: t(".aria_label")) do
      RubyUI.SidebarMenu do
        items.each { |item| render_item(item) }
      end
    end
  end

  private

  def items
    [
      Item.new(t(".dashboard"), root_path),
      Item.new(t(".transactions"), nil),
      Item.new(t(".accounts"), accounts_path),
      Item.new(t(".cards"), nil),
      Item.new(t(".categories"), categories_path),
      Item.new(t(".settings"), settings_profile_path)
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
          RubyUI.Badge(variant: :outline, size: :sm, class: "ml-auto") { t(".soon") }
        end
      end
    end
  end
end
