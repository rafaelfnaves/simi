# frozen_string_literal: true

class Components::FlashMessages < Components::Base
  include Phlex::Rails::Helpers::Flash

  VARIANTS = { "notice" => :success, "alert" => :destructive }.freeze

  def view_template
    return if messages.empty?

    div(class: "flex flex-col gap-2") do
      messages.each do |kind, message|
        RubyUI.Alert(variant: VARIANTS.fetch(kind, nil), role: "status") do
          RubyUI.AlertDescription { message }
        end
      end
    end
  end

  private

  def messages
    flash.to_h.slice(*VARIANTS.keys).reject { |_kind, message| message.blank? }
  end
end
