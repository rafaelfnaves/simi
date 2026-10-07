# frozen_string_literal: true

class Components::UserMenu < Components::Base
  include Phlex::Rails::Helpers::ButtonTo

  def view_template
    return unless Current.user

    RubyUI.DropdownMenu do
      RubyUI.DropdownMenuTrigger do
        RubyUI.Button(variant: :ghost, class: "flex items-center gap-2") do
          RubyUI.Avatar(size: :sm) { RubyUI.AvatarFallback { initials } }
          span(class: "hidden sm:inline") { Current.user.name }
        end
      end

      RubyUI.DropdownMenuContent(class: "w-56") do
        RubyUI.DropdownMenuLabel { Current.user.email_address }
        RubyUI.DropdownMenuSeparator
        RubyUI.DropdownMenuItem(href: settings_profile_path) { t(".profile") }
        RubyUI.DropdownMenuSeparator
        RubyUI.DropdownMenuItem do
          button_to t(".sign_out"), session_path, method: :delete, class: "w-full text-left"
        end
      end
    end
  end

  private

  def initials
    Current.user.name.split.first(2).map { |part| part[0] }.join.upcase
  end
end
