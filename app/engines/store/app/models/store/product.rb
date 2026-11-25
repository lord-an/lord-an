module Store
  class Product < ApplicationRecord
    include Notifications

    has_many :reviews, dependent: :destroy
    has_many :translations, class_name: "Store::ProductTranslation", dependent: :destroy
    has_many :wishlist_products, dependent: :destroy
    has_many :wishlists, through: :wishlist_products
    has_one_attached :featured_image
    has_rich_text :description

    validates :name, presence: true
    validates :inventory_count, numericality: { greater_than_or_equal_to: 0 }

    accepts_nested_attributes_for :translations, reject_if: :translation_blank?

    def localized_name(locale = I18n.locale)
      translation_for(locale)&.name.presence || name
    end

    def localized_description(locale = I18n.locale)
      translation = translation_for(locale)
      translation&.rich_text_description&.body&.present? ? translation.description : description
    end

    def rating_percentage(value)
      return 0 if reviews_count.zero?

      (reviews.where(rating: value).count.to_f / reviews_count * 100).round
    end

    private
      def translation_for(locale)
        translations.find { |translation| translation.locale == locale.to_s }
      end

      def translation_blank?(attributes)
        attributes["name"].blank? && attributes["description"].blank?
      end
  end
end
