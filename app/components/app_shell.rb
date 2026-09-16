# frozen_string_literal: true

class Components::AppShell < Components::Base
  def view_template(&block)
    RubyUI.SidebarWrapper do
      RubyUI.Sidebar(collapsible: :offcanvas) do
        RubyUI.SidebarHeader do
          span(class: "px-2 text-lg font-semibold tracking-tight") { "SIMI" }
        end
        RubyUI.SidebarContent { render Components::MainNav.new }
      end

      RubyUI.SidebarInset do
        header(class: "flex h-14 items-center gap-2 border-b px-4") do
          RubyUI.SidebarTrigger(class: "md:hidden")
          div(class: "ml-auto flex items-center gap-2") do
            render Components::ThemeSwitcher.new(theme: Current.user.theme)
            render Components::UserMenu.new
          end
        end

        div(class: "flex flex-1 flex-col gap-6 p-4 md:p-6") do
          render Components::FlashMessages.new
          yield
        end
      end
    end
  end
end
