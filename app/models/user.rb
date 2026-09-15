class User < ApplicationRecord
  THEMES = %w[system light dark].freeze
  MINIMUM_PASSWORD_LENGTH = 8
  # Stored as IANA identifiers, not the friendlier Rails zone names, so the value
  # means the same thing outside Rails.
  TIME_ZONES = ActiveSupport::TimeZone::MAPPING.values.uniq.freeze
  EMAIL_CONFIRMATION_EXPIRES_IN = 24.hours

  has_secure_password
  has_many :sessions, dependent: :destroy

  normalizes :email_address, with: ->(e) { e.strip.downcase }
  normalizes :name, with: ->(n) { n.strip }

  validates :name, presence: true
  validates :email_address, presence: true, uniqueness: true
  validates :password, length: { minimum: MINIMUM_PASSWORD_LENGTH }, allow_nil: true
  validates :theme, inclusion: { in: THEMES }
  validates :time_zone, inclusion: { in: TIME_ZONES }

  generates_token_for :email_confirmation, expires_in: EMAIL_CONFIRMATION_EXPIRES_IN do
    email_address
  end

  # Addresses cleared to register, newline- or comma-separated in the
  # environment. An unset or empty list means nobody may sign up — never the
  # other way around.
  #
  # @return [Array<String>]
  def self.allowed_signup_email_addresses
    ENV.fetch("SIMI_ALLOWED_SIGNUP_EMAILS", "").split(/[,\n]/).filter_map do |address|
      normalized = address.strip.downcase
      normalized.presence
    end
  end

  # @param email_address [String, nil]
  # @return [Boolean]
  def self.signup_allowed?(email_address)
    return false if email_address.blank?

    allowed_signup_email_addresses.include?(email_address.strip.downcase)
  end

  def confirmed?
    confirmed_at.present?
  end

  def confirm!
    update!(confirmed_at: Time.current) unless confirmed?
  end
end
