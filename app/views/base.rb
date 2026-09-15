# frozen_string_literal: true

class Views::Base < Components::Base
  # More caching options at https://www.phlex.fun/components/caching
  def cache_store = Rails.cache

  private

  def around_template
    render Components::AppShell.new do
      yield
    end
  end
end
