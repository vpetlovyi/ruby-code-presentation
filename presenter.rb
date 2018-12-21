class Payment::Presenter < ApplicationPresenter
  field :amount
  field :description

  field :descriptor
  field :external_ref, role: :root

  data :member_credit, -> { self.member_credit }

  embed :payment_method do
    field :method
    field :company
    field :last_four
  end

  embed :account_payments, role: :root do
    field :balance_amount
    field :transfer_amount
    field :transfer_id

    embed :account do
      field :name
    end
  end

  embed :member do
    embed :user do
      embed :first_name
      embed :last_name
    end
  end
end
