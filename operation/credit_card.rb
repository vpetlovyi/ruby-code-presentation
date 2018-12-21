class Payment::Operation::CreditCard < Application::Operation::Create
  include Helpers

  mailer

  job do
    [self['policy_model'].organization_id, self['policy_model'].id]
  end

  property :amount, :positive_amount?
  property :braintree_nonce
  property :source

  property :member_id

  policy_model Member

  def run
    payload = {
      nonce: sanitized(:braintree_nonce),
      amount: sanitized(:amount),
      descriptor: {
        name: Payment.descriptor(self['policy_model'].user),
        phone: '2025587717',
      }
    }

    results = Services::Braintree::Transaction.create_from_nonce(payload)

    unless results[:successful]
      self['context_validation'] = Struct
        .new(:success?, :errors)
        .new(false, {
          '_': [results[:error]]
        })
      return false
    end

    self['model'].description = "#{results[:credit_card][:company]} ending in #{results[:credit_card][:last_four]}"
    self['model'].amount = results[:amount]
    self['model'].external_ref = "bt:#{results[:transaction_id]}"
    self['model'].descriptor = results[:descriptor]

    true
  end

  def success
    op = AccountPayment::Operation::Process.(self['context'], payment_id: self['model'].id)

    unless op.successful?
      Rollbar.critical('Failed to create AccountPayments from a credit card payment', payment_id: self['model'].id)
      raise 'Failed to create AccountPayments from a credit card payment'
    end

    Member::Cache::Balances.invalidate(self['policy_model'].organization_id, self['policy_model'].id)

    PushNotificationsWorker.perform_async(
      title: "A payment of #{money self['model'].amount} has been made",
      message: "Your balance is now #{money self['policy_model'].balance}",
      member_id: self['policy_model'].id,
      data: {
        route: '/balance'
      }
    )
  end
end
