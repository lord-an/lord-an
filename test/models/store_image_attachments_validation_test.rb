require "test_helper"
require "base64"

class StoreImageAttachmentsValidationTest < ActiveSupport::TestCase
  MAX_IMAGE_SIZE = 5.megabytes

  test "products reject non-image featured uploads" do
    product = build_product
    product.featured_image.attach(upload("image/png", "notes.png", "not an image"))

    assert_not product.valid?
    assert_includes product.errors[:featured_image], "must be an image"
  end

  test "products accept supported images within the size limit" do
    product = build_product
    product.featured_image.attach(upload("image/png", "pixel.png", pixel_png))

    assert product.valid?, product.errors.full_messages.to_sentence
  end

  test "products reject oversized featured uploads" do
    product = build_product
    product.featured_image.attach(upload("image/png", "large.png", "x" * (MAX_IMAGE_SIZE + 1)))

    assert_not product.valid?
    assert_includes product.errors[:featured_image], "must be smaller than 5 MB"
  end

  test "reviews reject too many images" do
    review = Store::Review.new(product: build_product, user: users(:one), rating: 5, body: "Looks good.")
    review.images.attach(Array.new(6) { upload("image/png", "pixel.png", pixel_png) })

    assert_not review.valid?
    assert_includes review.errors[:images], "cannot include more than 5 files"
  end

  test "reviews reject non-image and oversized uploads" do
    review = Store::Review.new(product: build_product, user: users(:one), rating: 5, body: "Looks good.")
    review.images.attach(
      upload("text/plain", "notes.txt", "not an image"),
      upload("image/png", "large.png", "x" * (MAX_IMAGE_SIZE + 1))
    )

    assert_not review.valid?
    assert_includes review.errors[:images], "must be an image"
    assert_includes review.errors[:images], "must be smaller than 5 MB"
  end

  private
    def build_product
      Store::Product.new(name: "Desk Lamp", inventory_count: 1, price_cents: 2200, currency_code: "USD")
    end

    def upload(content_type, filename, content)
      { io: StringIO.new(content.b), filename: filename, content_type: content_type }
    end

    def pixel_png
      Base64.decode64("iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+jNPsAAAAASUVORK5CYII=")
    end
end
