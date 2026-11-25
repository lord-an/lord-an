module Store
  class ProductTranslation < ApplicationRecord
    belongs_to :product
    has_rich_text :description

    validates :locale, inclusion: { in: Internationalization::SUPPORTED_LOCALES - [ "en" ] }
    validates :name, presence: true
  end
end
