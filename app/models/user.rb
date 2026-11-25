class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy
  has_many :reviews, class_name: "Store::Review", dependent: :destroy
  has_many :wishlists, class_name: "Store::Wishlist", dependent: :destroy

  validates :preferred_locale, inclusion: { in: Internationalization::SUPPORTED_LOCALES }
  validates :password, length: { minimum: 12 }, if: -> { password.present? }

  normalizes :email_address, with: ->(email) { email.strip.downcase }

  generates_token_for :password_reset, expires_in: 15.minutes do
    password_digest.last(10)
  end
end
