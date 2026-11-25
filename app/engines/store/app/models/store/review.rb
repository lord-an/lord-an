module Store
  class Review < ApplicationRecord
    belongs_to :product, counter_cache: true
    belongs_to :user, class_name: "::User"
    has_many_attached :images

    scope :rated, ->(rating) { rating.present? ? where(rating: rating.to_i) : all }

    validates :body, presence: true
    validates :rating, presence: true, numericality: { only_integer: true, in: 1..5 }

    after_commit :update_product_rating

    def self.filter_by(params)
      results = rated(params[:rating])
      results = results.where(product_id: params[:product_id]) if params[:product_id].present?
      results = results.where(user_id: params[:user_id]) if params[:user_id].present?
      results
    end

    private
      def update_product_rating
        product_record = Product.find_by(id: product_id)
        return unless product_record

        average = product_record.reviews.average(:rating)&.round(1)
        product_record.update_column(:rating, average)
      end
  end
end
