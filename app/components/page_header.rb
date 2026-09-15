# frozen_string_literal: true

class Components::PageHeader < Components::Base
  def initialize(title:, subtitle: nil)
    @title = title
    @subtitle = subtitle
  end

  def view_template(&block)
    header(class: "flex flex-wrap items-start justify-between gap-4") do
      div(class: "flex flex-col gap-1") do
        h1(class: "text-2xl font-semibold tracking-tight") { @title }
        p(class: "text-sm text-muted-foreground") { @subtitle } if @subtitle
      end

      div(class: "flex items-center gap-2") { yield } if block
    end
  end
end
