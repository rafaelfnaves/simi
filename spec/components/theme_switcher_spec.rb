require "rails_helper"

RSpec.describe Components::ThemeSwitcher do
  def fragment_for(theme)
    Nokogiri::HTML5.fragment(render_component(described_class.new(theme: theme)))
  end

  def submitted_theme(fragment)
    fragment.at_css("input[name='theme']")[:value]
  end

  it "sends the change to the account as a patch" do
    form = fragment_for("light").at_css("form")

    expect(form[:action]).to eq("/settings/theme")
    expect(form[:method]).to eq("post")
    expect(form.at_css("input[name='_method']")[:value]).to eq("patch")
  end

  it "offers the dark theme to an account on the light one" do
    expect(submitted_theme(fragment_for("light"))).to eq("dark")
  end

  it "offers the light theme to an account on the dark one" do
    expect(submitted_theme(fragment_for("dark"))).to eq("light")
  end

  it "offers the dark theme to an account that follows the system" do
    expect(submitted_theme(fragment_for("system"))).to eq("dark")
  end

  it "marks the trigger as pressed only on the dark theme" do
    expect(fragment_for("dark").at_css("button")[:"aria-pressed"]).to eq("true")
    expect(fragment_for("light").at_css("button")[:"aria-pressed"]).to eq("false")
  end

  it "wires the trigger to the controller that flips the class right away" do
    fragment = fragment_for("system")

    expect(fragment.at_css("[data-controller~='theme']")).to be_present
  end

  # Anything but a click loops: the toggle re-announces its state every time
  # Turbo renders the page the redirect lands on, and each announcement would
  # submit the form again.
  it "submits only on a click" do
    action = fragment_for("system").at_css("form")[:"data-action"]

    expect(action).to eq("click->theme#apply")
  end

  # Turbo replaces the body but never the attributes of `<html>`, so the class
  # the layout rendered goes stale the moment the theme is saved from the
  # profile. The controller needs the preference to put it back.
  it "hands the account's preference to the controller" do
    %w[system light dark].each do |theme|
      element = fragment_for(theme).at_css("[data-theme-preference-value]")

      expect(element[:"data-theme-preference-value"]).to eq(theme)
    end
  end

  it "names itself for screen readers" do
    expect(fragment_for("light").at_css("button")[:"aria-label"]).to be_present
  end
end
