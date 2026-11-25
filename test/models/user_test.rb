require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "downcases and strips email_address" do
    user = User.new(email_address: " DOWNCASED@EXAMPLE.COM ")
    assert_equal("downcased@example.com", user.email_address)
  end

  test "requires a password with at least twelve characters" do
    user = User.new(email_address: "short-password@example.com", password: "too-short")

    assert_not user.valid?
    assert_includes user.errors[:password], "is too short (minimum is 12 characters)"
  end

  test "accepts a password with twelve characters" do
    user = User.new(
      email_address: "minimum-password@example.com",
      password: "twelve-chars",
      password_confirmation: "twelve-chars"
    )

    assert_predicate user, :valid?
  end
end
