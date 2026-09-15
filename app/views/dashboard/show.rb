# frozen_string_literal: true

class Views::Dashboard::Show < Views::Base
  def view_template
    h1(class: "text-2xl font-semibold tracking-tight") { "Dashboard" }
  end
end
