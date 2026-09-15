# frozen_string_literal: true

# Pages reachable without a session: sign in, sign up, password recovery and
# email confirmation. They get a centred shell with no navigation.
class Views::AuthBase < Views::Base
  private

  def around_template
    render Components::AuthShell.new(title: page_title, subtitle: page_subtitle) do
      yield
    end
  end

  def page_title
    raise NotImplementedError, "#{self.class} must define #page_title"
  end

  def page_subtitle = nil
end
