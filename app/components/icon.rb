# frozen_string_literal: true

# The closed set of icons a category can wear.
#
# Glyphs are drawn here rather than pulled from an icon gem: the set is small and
# fixed, and the vendored RubyUI components already draw their own SVG inline. The
# geometry follows the same convention they use — a 24×24 box, 2px round strokes,
# `currentColor` — so an icon inherits the colour of whatever contains it.
class Components::Icon < Components::Base
  class UnknownIcon < ArgumentError; end

  CATALOG = {
    "home" => [
      [ :path, { d: "M3 11 12 4l9 7" } ],
      [ :path, { d: "M5 11v9h14v-9" } ]
    ],
    "food" => [
      [ :path, { d: "M7 3v18" } ],
      [ :path, { d: "M5 3v5a2 2 0 0 0 4 0V3" } ],
      [ :path, { d: "M17 3v18" } ],
      [ :path, { d: "M15 3h4v6h-4z" } ]
    ],
    "car" => [
      [ :path, { d: "M5 16v-3l2-5h10l2 5v3" } ],
      [ :path, { d: "M3 16h18" } ],
      [ :circle, { cx: "8", cy: "18", r: "1.5" } ],
      [ :circle, { cx: "16", cy: "18", r: "1.5" } ]
    ],
    "health" => [
      [ :rect, { x: "3", y: "3", width: "18", height: "18", rx: "3" } ],
      [ :path, { d: "M12 8v8" } ],
      [ :path, { d: "M8 12h8" } ]
    ],
    "education" => [
      [ :path, { d: "M3 9 12 5l9 4-9 4z" } ],
      [ :path, { d: "M7 11.5V17c0 1.1 2.2 2 5 2s5-.9 5-2v-5.5" } ]
    ],
    "leisure" => [
      [ :path, { d: "M12 4l2.5 5.1 5.5.8-4 3.9.9 5.6-4.9-2.7-4.9 2.7.9-5.6-4-3.9 5.5-.8z" } ]
    ],
    "shopping" => [
      [ :path, { d: "M6 8h12l-1 12H7z" } ],
      [ :path, { d: "M9 8V6a3 3 0 0 1 6 0v2" } ]
    ],
    "receipt" => [
      [ :path, { d: "M6 3h12v18l-3-2-3 2-3-2-3 2z" } ],
      [ :path, { d: "M9 8h6" } ],
      [ :path, { d: "M9 12h6" } ]
    ],
    "travel" => [
      [ :circle, { cx: "12", cy: "12", r: "9" } ],
      [ :path, { d: "M3 12h18" } ],
      [ :path, { d: "M12 3a15 15 0 0 1 0 18 15 15 0 0 1 0-18" } ]
    ],
    "work" => [
      [ :rect, { x: "3", y: "7", width: "18", height: "13", rx: "2" } ],
      [ :path, { d: "M9 7V5a2 2 0 0 1 2-2h2a2 2 0 0 1 2 2v2" } ]
    ],
    "gift" => [
      [ :rect, { x: "3", y: "8", width: "18", height: "12", rx: "2" } ],
      [ :path, { d: "M3 13h18" } ],
      [ :path, { d: "M12 8v12" } ],
      [ :path, { d: "M8 8 12 4l4 4" } ]
    ],
    "savings" => [
      [ :rect, { x: "3", y: "4", width: "18", height: "16", rx: "2" } ],
      [ :circle, { cx: "12", cy: "12", r: "4" } ],
      [ :path, { d: "M12 4v4" } ]
    ],
    "wallet" => [
      [ :rect, { x: "3", y: "6", width: "18", height: "13", rx: "2" } ],
      [ :path, { d: "M3 10h18" } ],
      [ :circle, { cx: "17", cy: "14.5", r: "1.5" } ]
    ],
    "other" => [
      [ :circle, { cx: "5", cy: "12", r: "1.5" } ],
      [ :circle, { cx: "12", cy: "12", r: "1.5" } ],
      [ :circle, { cx: "19", cy: "12", r: "1.5" } ]
    ]
  }.freeze

  NAMES = CATALOG.keys.freeze

  # @param name [String, Symbol] a key of {CATALOG}
  # @raise [UnknownIcon] when the name is not in the catalog, so a typo fails
  #   loudly instead of rendering an empty box
  def initialize(name, **attrs)
    @name = name.to_s
    @shapes = CATALOG.fetch(@name) { raise UnknownIcon, "unknown icon #{name.inspect}" }
    @attrs = attrs
  end

  def view_template
    svg(
      xmlns: "http://www.w3.org/2000/svg",
      viewBox: "0 0 24 24",
      fill: "none",
      stroke: "currentColor",
      stroke_width: "2",
      stroke_linecap: "round",
      stroke_linejoin: "round",
      aria_hidden: "true",
      class: "size-4 shrink-0",
      **@attrs
    ) { |s| @shapes.each { |tag, shape| s.public_send(tag, **shape) } }
  end
end
