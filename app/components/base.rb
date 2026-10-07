# frozen_string_literal: true

class Components::Base < Phlex::HTML
  include RubyUI
  # Include any helpers you want to be available across all components
  include Phlex::Rails::Helpers::Routes
  # Resolves ".key" against the class name, so Views::Accounts::Index reads
  # views.accounts.index.key
  include Phlex::Rails::Helpers::T

  if Rails.env.development?
    def before_template
      comment { "Before #{self.class.name}" }
      super
    end
  end
end
