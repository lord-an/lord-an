module Store
  class Subscriber < ApplicationRecord
    belongs_to :product

    CONFIRMATION_EMAIL_INTERVAL = 30.minutes

    normalizes :email, with: ->(email) { email.strip.downcase }

    generates_token_for :confirmation, expires_in: 24.hours do
      confirmed_at
    end
    generates_token_for :unsubscribe

    scope :confirmed, -> { where.not(confirmed_at: nil) }

    validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
    validates :email, uniqueness: { scope: :product_id, case_sensitive: false }

    def confirmed?
      confirmed_at.present?
    end

    def confirmation_email_due?
      confirmation_sent_at.nil? || confirmation_sent_at <= CONFIRMATION_EMAIL_INTERVAL.ago
    end
  end
end
