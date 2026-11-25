require "application_system_test_case"

class StorefrontTest < ApplicationSystemTestCase
  test "visitors can browse the storefront from the application root" do
    visit "/"

    assert_current_path "/store"
    assert_text "Products"
  end
end
