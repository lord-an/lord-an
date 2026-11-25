module LunaStyle
  class ThemeSetting < ApplicationRecord
    THEMES = %w[classic forest sunrise].freeze

    validates :key, presence: true
    validates :theme, inclusion: { in: THEMES }

    def self.current
      create_or_find_by!(key: "storefront")
    end
  end
end
