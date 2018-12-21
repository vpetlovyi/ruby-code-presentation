class Payment::Mailers::CreditCard < ApplicationMailer
  def self.call(id)
    payment = Payment.find id

    member = payment.member

    invoice = generate_invoice(member)

    descriptor = payment.descriptor.present? ?
                   " <br />The charge will appear on your credit card as #{payment.descriptor}" :
                   ''

    payload = {
      subject: 'A payment has been made on your payment plan',
      masthead: {
        headline: "A payment has been made of #{money payment.member_credit}",
        content: "The balance on #{member.user.first_name}'s account is now #{money member.balance}#{descriptor}",
      },
      action: {
        title: 'Quick Pay',
        url: urlize("/quick-pay/#{member.unique_id}"),
        description: 'Pay without logging in with Quick Pay'
      },
      footer: {
        content: "#{member.user.first_name}'s unique ID is #{member.unique_id}"
      },
      quick_action: {
        name: 'Quick Pay',
        url: urlize("/quick-pay/#{member.unique_id}"),
      },
      attachments: [invoice]
    }

    all_recipients(member).map do |recipient|
      payload.merge recipients: [recipient]
    end
  end
end
