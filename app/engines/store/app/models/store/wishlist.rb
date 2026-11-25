module Store
  class Wishlist < ApplicationRecord
    belongs_to :user, class_name: "::User"
    has_many :wishlist_products, dependent: :destroy
    has_many :products, through: :wishlist_products

    validates :name, presence: true

    def to_param
      "#{id}-#{name.to_s.squish.parameterize}"
    end

    def self.filter_by(params)
      results = all
      results = results.where(user_id: params[:user_id]) if params[:user_id].present?
      results = results.joins(:wishlist_products).where(store_wishlist_products: { product_id: params[:product_id] }) if params[:product_id].present?
      results.distinct
    end
  end
end
