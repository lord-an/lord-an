module Store
  class Subscriber < ApplicationRecord
    belongs_to :product

    generates_token_for :unsubscribe

    validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  end
end
