class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy
  has_many :wishlists, class_name: "Store::Wishlist", dependent: :destroy
end
