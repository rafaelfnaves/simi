# A label the person classifies their entries with. Two levels deep: a category
# and its subcategories, as PRD §9 describes them.
class Category < ApplicationRecord
  # Which icons a category may wear. The authority is here, in the domain;
  # Components::Icon has to be able to draw every one of them, and a spec holds it
  # to that.
  ICONS = %w[
    home food car health education leisure shopping receipt travel work gift savings wallet other
  ].freeze

  # Tailwind cannot compile a class name that was built by interpolation, so every
  # palette entry is a literal string the source scanner can find.
  COLORS = {
    "slate" => "bg-slate-500/15 text-slate-700 dark:text-slate-300",
    "rose" => "bg-rose-500/15 text-rose-700 dark:text-rose-300",
    "orange" => "bg-orange-500/15 text-orange-700 dark:text-orange-300",
    "amber" => "bg-amber-500/15 text-amber-700 dark:text-amber-300",
    "lime" => "bg-lime-500/15 text-lime-700 dark:text-lime-300",
    "emerald" => "bg-emerald-500/15 text-emerald-700 dark:text-emerald-300",
    "teal" => "bg-teal-500/15 text-teal-700 dark:text-teal-300",
    "sky" => "bg-sky-500/15 text-sky-700 dark:text-sky-300",
    "violet" => "bg-violet-500/15 text-violet-700 dark:text-violet-300",
    "fuchsia" => "bg-fuchsia-500/15 text-fuchsia-700 dark:text-fuchsia-300"
  }.freeze

  # Offered only while the person has no category at all, and created as ordinary
  # categories of theirs — editable, archivable, with no mark of origin.
  SUGGESTED = [
    { name: "Moradia", nature: "expense", color: "slate", icon: "home" },
    { name: "Alimentação", nature: "expense", color: "amber", icon: "food",
      children: [ "Mercado", "Restaurantes", "Delivery" ] },
    { name: "Transporte", nature: "expense", color: "sky", icon: "car",
      children: [ "Combustível", "Transporte por app" ] },
    { name: "Saúde", nature: "expense", color: "rose", icon: "health" },
    { name: "Educação", nature: "expense", color: "violet", icon: "education" },
    { name: "Lazer", nature: "expense", color: "fuchsia", icon: "leisure" },
    { name: "Compras", nature: "expense", color: "orange", icon: "shopping" },
    { name: "Assinaturas", nature: "expense", color: "teal", icon: "receipt" },
    { name: "Outros gastos", nature: "expense", color: "slate", icon: "other" },
    { name: "Salário", nature: "income", color: "emerald", icon: "work" },
    { name: "Investimentos", nature: "income", color: "lime", icon: "savings" },
    { name: "Outras receitas", nature: "income", color: "emerald", icon: "other" }
  ].freeze

  NATURE_LABELS = { "expense" => "Despesa", "income" => "Receita" }.freeze

  belongs_to :user
  belongs_to :parent, class_name: "Category", optional: true
  has_many :subcategories, class_name: "Category", foreign_key: :parent_id,
    inverse_of: :parent, dependent: :restrict_with_error

  enum :nature, { expense: "expense", income: "income" }, validate: true

  normalizes :name, with: ->(name) { name.strip }

  before_validation :inherit_nature_from_parent

  validates :name, presence: true
  validates :color, inclusion: { in: COLORS.keys }
  validates :icon, inclusion: { in: ICONS }
  validates :name,
    uniqueness: { scope: %i[ user_id parent_id nature ], case_sensitive: false,
                  conditions: -> { active } },
    if: :active?
  validate :parent_must_belong_to_the_same_user
  validate :parent_must_be_a_root
  validate :nature_cannot_change, on: :update

  scope :active, -> { where(archived_at: nil) }
  scope :archived, -> { where.not(archived_at: nil) }
  scope :roots, -> { where(parent_id: nil) }
  scope :by_name, -> { order(Arel.sql("lower(name)")) }

  # Creates the suggested set for someone who has no categories yet. Idempotent:
  # a name the person already has, active or archived, is skipped rather than
  # duplicated or revived.
  #
  # @param user [User]
  # @return [Integer] how many categories were created
  def self.create_suggested_for(user)
    transaction do
      SUGGESTED.sum { |entry| create_suggested_entry(user, entry) }
    end
  end

  def self.create_suggested_entry(user, entry)
    return 0 if user.categories.roots.where("lower(name) = ?", entry[:name].downcase).exists?

    root = user.categories.create!(entry.except(:children))

    1 + entry.fetch(:children, []).sum do |child|
      root.subcategories.create!(user:, name: child, color: root.color, icon: root.icon)
      1
    end
  end
  private_class_method :create_suggested_entry

  def active? = archived_at.nil?

  def archived? = !active?

  def root? = parent_id.nil?

  # @return [String] the literal Tailwind classes for this category's colour
  def color_classes = COLORS.fetch(color)

  def archive!
    return if archived?

    transaction do
      now = Time.current
      subcategories.active.update_all(archived_at: now, updated_at: now)
      update!(archived_at: now)
    end
  end

  # Reactivating a parent leaves its subcategories alone: some may have been
  # archived on purpose, before the parent was.
  def unarchive!
    update!(archived_at: nil)
  end

  private
    def inherit_nature_from_parent
      self.nature = parent.nature if parent
    end

    def parent_must_belong_to_the_same_user
      errors.add(:parent_id, :invalid) if parent && parent.user_id != user_id
    end

    def parent_must_be_a_root
      errors.add(:parent_id, "only accepts two levels of category") unless parent.nil? || parent.root?
    end

    def nature_cannot_change
      errors.add(:nature, "cannot change after creation") if nature_changed?
    end
end
