# frozen_string_literal: true

# Phlex components need a Rails view context before helpers like routes or
# `form_with` become available, so component specs render through a real one
# instead of calling the component directly.
module ComponentRendering
  def render_component(component)
    view_context.render(component)
  end

  def render_fragment(component)
    Nokogiri::HTML5.fragment(render_component(component))
  end

  def view_context
    @view_context ||= ApplicationController.new.tap do |controller|
      controller.request = ActionDispatch::TestRequest.create
    end.view_context
  end
end

RSpec.configure do |config|
  config.define_derived_metadata(file_path: %r{/spec/components/}) do |metadata|
    metadata[:type] = :component
  end

  config.include ComponentRendering, type: :component
end
