module Accounts
  class Cash < Deposit
    # Cash has no issuer, and leaving the field open would invite inventing one.
    validates :institution, absence: true
  end
end
