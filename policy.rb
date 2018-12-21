class Payment::Policy < ApplicationPolicy
  allow_root :retrieve, :check, :refund, :list

  def credit_card?
    family? or admin? or root?
  end

  def payment_method?
    self? or parent?
  end
end
