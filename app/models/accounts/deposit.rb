module Accounts
  # An account that holds money, and therefore sums into net worth. Its opposite is
  # a line of credit, which arrives with the cards of feature 003.
  class Deposit < Account
    # Listed instead of derived from `descendants`: outside eager loading Rails has
    # not seen the leaf classes yet, and the inherited STI condition collapses to
    # `type = 'Accounts::Deposit'`, which matches nothing. That failure would pass
    # in CI, where eager loading is on, and lose every balance in development.
    TYPES = %w[
      Accounts::Checking
      Accounts::Savings
      Accounts::Wallet
      Accounts::Cash
    ].freeze
  end
end
