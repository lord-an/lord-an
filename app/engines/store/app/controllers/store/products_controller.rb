module Store
  class ProductsController < ApplicationController
    allow_unauthenticated_access only: %i[ index show ]
    before_action :set_product, only: %i[ show edit update destroy ]
    before_action :require_admin, only: %i[ new create edit update destroy ]

    def index
      @query = params[:q].to_s.strip
      @sort = %w[ price_asc price_desc ].include?(params[:sort]) ? params[:sort] : "newest"
      @products = Product.with_attached_featured_image.includes(:translations)

      if @query.present?
        search_pattern = "%#{Product.sanitize_sql_like(@query)}%"
        @products = @products.left_joins(:translations).where(
          "store_products.name LIKE :query OR store_product_translations.name LIKE :query", query: search_pattern
        ).distinct
      end

      @products = case @sort
      when "price_asc"
        @products.order(price_cents: :asc, id: :asc)
      when "price_desc"
        @products.order(price_cents: :desc, id: :desc)
      else
        @products.order(created_at: :desc, id: :desc)
      end
    end

    def show
      @reviews = @product.reviews.with_attached_images.rated(params[:rating])
    end

    def new
      @product = Product.new
      prepare_translations
    end

    def create
      @product = Product.new(product_params)
      if @product.save
        redirect_to @product, notice: t("store.products.created")
      else
        prepare_translations
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      prepare_translations
    end

    def update
      if @product.update(product_params)
        redirect_to @product, notice: t("store.products.updated")
      else
        prepare_translations
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @product.destroy!
      redirect_to products_path, status: :see_other
    end

    private
      def set_product
        @product = Product.find(params[:id])
      end

      def require_admin
        return if Current.user&.admin?

        redirect_to "/store", alert: t("store.authorization.admin_required")
      end

      def product_params
        params.expect(product: [ :name, :description, :featured_image, :inventory_count, :shipping_weight_grams, :avatax_tax_code, :price_cents, :currency_code,
          { translations_attributes: [ [ :id, :locale, :name, :description ] ] } ])
      end

      def prepare_translations
        (Internationalization::SUPPORTED_LOCALES - [ "en" ]).each do |locale|
          @product.translations.find_or_initialize_by(locale: locale)
        end
      end
  end
end
