require "rails_helper"

RSpec.describe Components::Icon do
  it "draws every icon in the catalog" do
    described_class::NAMES.each do |name|
      fragment = render_fragment(described_class.new(name))
      svg = fragment.at_css("svg")

      expect(svg).to be_present, "#{name} rendered no svg"
      expect(svg["aria-hidden"]).to eq("true")
      expect(svg["viewBox"]).to eq("0 0 24 24")
      expect(svg.element_children).not_to be_empty, "#{name} rendered an empty svg"
    end
  end

  it "can draw every icon a category may wear" do
    expect(described_class::NAMES).to match_array(Category::ICONS)
  end

  it "refuses a name that is not in the catalog" do
    expect { described_class.new(:bitcoin) }.to raise_error(described_class::UnknownIcon, /bitcoin/)
  end

  it "accepts extra attributes without losing its own classes" do
    fragment = render_fragment(described_class.new("home", class: "size-6"))

    expect(fragment.at_css("svg")["class"]).to include("size-6")
  end
end
