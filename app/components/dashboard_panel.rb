# frozen_string_literal: true

# A titled dashboard block. Phase 2 of the roadmap swaps the empty state for
# real data without touching the page that arranges these.
class Components::DashboardPanel < Components::Base
  def initialize(title:, empty_title:, empty_description:)
    @title = title
    @empty_title = empty_title
    @empty_description = empty_description
  end

  def view_template
    RubyUI.Card(class: "p-5 flex flex-col gap-4") do
      h2(class: "text-sm font-medium text-muted-foreground") { @title }

      RubyUI.Empty do
        RubyUI.EmptyHeader do
          RubyUI.EmptyTitle { @empty_title }
          RubyUI.EmptyDescription { @empty_description }
        end
      end
    end
  end
end
