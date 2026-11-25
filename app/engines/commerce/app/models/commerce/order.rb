module Commerce
  class Order < ApplicationRecord
    STATUSES = %w[ pending_payment paid cancelled ].freeze

    belongs_to :user, class_name: "::User"
    has_many :items, class_name: "Commerce::OrderItem", dependent: :destroy

    validates :status, inclusion: { in: STATUSES }
    validates :currency_code, format: { with: /\A[A-Z]{3}\z/ }
    validates :total_cents, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  end
end
