require "application_system_test_case"

class StorefrontTest < ApplicationSystemTestCase
  test "visitors can browse the storefront from the application home page" do
    visit "/"

    assert_current_path "/"
    assert_text "Find your next favorite."

    click_link "Explore the store"

    assert_current_path "/store"
    assert_text "Products"
  end
end
