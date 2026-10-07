# frozen_string_literal: true

# How a category shows up anywhere it is mentioned. The transactions of feature
# 003 reuse this instead of printing a bare name.
class Components::CategoryBadge < Components::Base
  def initialize(category, **attrs)
    @category = category
    @attrs = attrs
  end

  def view_template
    span(
      **@attrs,
      class: [
        "inline-flex items-center gap-1.5 rounded-full px-2 py-0.5 text-xs font-medium",
        @category.color_classes, @attrs[:class]
      ]
    ) do
      render Components::Icon.new(@category.icon, class: "size-3.5")
      plain @category.name
    end
  end
end
