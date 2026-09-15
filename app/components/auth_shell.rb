# frozen_string_literal: true

class Components::AuthShell < Components::Base
  def initialize(title:, subtitle: nil)
    @title = title
    @subtitle = subtitle
  end

  def view_template(&block)
    main(class: "flex min-h-svh items-center justify-center px-4 py-12") do
      div(class: "w-full max-w-sm flex flex-col gap-6") do
        header(class: "flex flex-col gap-2 text-center") do
          span(class: "text-2xl font-semibold tracking-tight") { "SIMI" }
          h1(class: "text-lg font-medium") { @title }
          p(class: "text-sm text-muted-foreground") { @subtitle } if @subtitle
        end

        render Components::FlashMessages.new

        yield
      end
    end
  end
end
