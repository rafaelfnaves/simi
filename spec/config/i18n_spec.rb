# frozen_string_literal: true

require "rails_helper"

# The suite itself is the main guard against a missing key, because
# `raise_on_missing_translations` is on in test: any page a request spec renders
# fails loudly if a translation disappears. What is left to assert is the wiring
# and the vocabularies no page happens to render in full.
RSpec.describe "i18n configuration" do
  it "speaks Brazilian Portuguese, and only that" do
    expect(I18n.default_locale).to eq(:"pt-BR")
    expect(I18n.available_locales).to eq([ :"pt-BR" ])
  end

  it "raises on a missing translation instead of rendering the key" do
    expect(Rails.application.config.i18n.raise_on_missing_translations).to be(true)
  end

  it "translates what Rails itself says" do
    expect(I18n.t("errors.messages.blank")).to eq("não pode ficar em branco")
    expect(I18n.t("errors.messages.taken")).to eq("já está em uso")
  end

  it "words validation messages so they agree with attributes of either gender" do
    category = Category.new
    category.valid?

    expect(category.errors.full_messages).to include(
      "Usuário não pode ficar em branco",
      "Natureza não é uma opção válida"
    )
  end

  it "formats money the way Brazil writes it" do
    expect(ActiveSupport::NumberHelper.number_to_currency(1234.56)).to eq("R$ 1.234,56")
    expect(ActiveSupport::NumberHelper.number_to_currency(-90)).to eq("-R$ 90,00")
  end

  describe "the vocabularies a form offers" do
    it "names every kind of account" do
      expect(Account::KINDS.keys).to all(satisfy { |kind| Account.human_kind(kind).present? })
    end

    it "names every nature, colour and icon a category can wear" do
      expect(Category.natures_in_order).to all(satisfy { |n| Category.human_nature(n).present? })
      expect(Category::COLORS.keys).to all(satisfy { |c| Category.human_color(c).present? })
      expect(Category::ICONS).to all(satisfy { |i| Category.human_icon(i).present? })
    end

    it "names every category the suggested set offers, roots and children alike" do
      keys = Category::SUGGESTED.flat_map { |entry| [ entry[:key], *entry[:children] ] }

      expect(keys).to all(satisfy { |key| Category.suggested_name(key).present? })
    end

    it "names every theme" do
      expect(User::THEMES).to all(satisfy { |theme| User.human_theme(theme).present? })
    end

    it "names every model and the attributes a person fills in" do
      expect(Account.model_name.human).to eq("Conta")
      expect(Category.model_name.human).to eq("Categoria")
      expect(Account.human_attribute_name(:balance)).to eq("Saldo")
      expect(User.human_attribute_name(:email_address)).to eq("E-mail")
    end

    # Subclasses have no entry of their own: ActiveModel::Name walks up the
    # ancestors, so adding Accounts::CreditCard in feature 003 needs no locale
    # change to read as "Conta".
    it "lets an STI subclass fall back to the name of its root" do
      expect(Accounts::Checking.model_name.human).to eq(Account.model_name.human)
    end
  end

  describe "the locale files" do
    let(:paths) { Dir[Rails.root.join("config/locales/*.yml")] }

    it "are all loaded" do
      expect(paths).not_to be_empty
      expect(paths.map { |path| File.basename(path) }).to all(start_with("pt-BR"))
    end

    it "declare no duplicate key, which YAML would silently resolve to the last one" do
      paths.each do |path|
        repeated = duplicate_keys(Psych.parse_file(path))

        expect(repeated).to be_empty, "#{File.basename(path)} repeats #{repeated.join(', ')}"
      end
    end

    # Walks the document rather than the text, so that the same key under two
    # different parents is not mistaken for a repetition.
    def duplicate_keys(node, path = [])
      return [] if node.nil? || node.children.nil?
      return node.children.flat_map { |child| duplicate_keys(child, path) } unless node.is_a?(Psych::Nodes::Mapping)

      pairs = node.children.each_slice(2).to_a
      repeated = pairs.map { |key, _| key.value }.tally.select { |_, count| count > 1 }.keys

      repeated.map { |key| (path + [ key ]).join(".") } +
        pairs.flat_map { |key, value| duplicate_keys(value, path + [ key.value ]) }
    end
  end
end
