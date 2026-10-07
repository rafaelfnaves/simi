# Root of the account hierarchy. A credit card is an account too — accounting has
# always treated one as an asset and the other as a liability — so both live in
# this table and a transaction needs only one foreign key. See
# specs/002-contas-categorias/research.md D1.
class Account < ApplicationRecord
  # The only kinds a form may ask for. The subclass is resolved through this map,
  # never from a parameter, so the browser cannot pick the class it instantiates.
  KINDS = {
    "checking" => "Accounts::Checking",
    "savings" => "Accounts::Savings",
    "wallet" => "Accounts::Wallet",
    "cash" => "Accounts::Cash"
  }.freeze

  belongs_to :user

  attribute :balance, MoneyType.new(precision: 15, scale: 2)

  normalizes :name, with: ->(name) { name.strip }
  normalizes :institution, with: ->(institution) { institution.strip.presence }

  validates :type, inclusion: { in: KINDS.values }
  validates :name, presence: true
  validates :balance, presence: true
  # `conditions` restricts what the query looks at, `if` decides whether this
  # record is subject to it at all: an archived account neither claims a name nor
  # has to defend one.
  validates :name,
    uniqueness: { scope: :user_id, case_sensitive: false, conditions: -> { active } },
    if: :active?
  validate :balance_must_read_as_money

  scope :deposits, -> { where(type: Accounts::Deposit::TYPES) }
  scope :active, -> { where(archived_at: nil) }
  scope :archived, -> { where.not(archived_at: nil) }
  scope :by_name, -> { order(Arel.sql("lower(name)")) }

  # @param kind [String, Symbol] a key of {KINDS}
  # @return [Class, nil] the subclass to instantiate, or nil for an unknown kind
  def self.class_for(kind)
    KINDS[kind.to_s]&.constantize
  end

  # @param kind [String, Symbol] a key of {KINDS}
  # @return [String] the name a person reads for that kind
  def self.human_kind(kind)
    I18n.t(kind, scope: %i[ activerecord attributes account kinds ])
  end

  # @return [String, nil] the form token for this record's subclass
  def kind
    KINDS.key(self.class.name)
  end

  # @return [String] this account's kind, as a person reads it
  def human_kind
    self.class.human_kind(kind)
  end

  def active? = archived_at.nil?

  def archived? = !active?

  def archive!
    update!(archived_at: Time.current) if active?
  end

  def unarchive!
    update!(archived_at: nil)
  end

  private
    def balance_must_read_as_money
      raw = balance_before_type_cast
      return unless raw.is_a?(String) && raw.strip.present?

      errors.add(:balance, :not_a_number) unless MoneyType.accepts?(raw)
    end
end
