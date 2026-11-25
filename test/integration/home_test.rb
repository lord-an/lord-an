require "test_helper"

class HomeTest < ActionDispatch::IntegrationTest
  test "homepage introduces the store and links to key customer actions" do
    get "/"

    assert_response :success
    assert_select "main.home-page"
    assert_select "h1#home-title", "Find your next favorite."
    assert_select "a.home-button[href='/store']", "Explore the store"
    assert_select "a.home-button[href='/authenticate/registrations/new']", "Create an account"
    assert_select "article.home-highlight", count: 3
    assert_select "h2#home-highlights-title", "More than a catalog"
  end

  test "homepage content follows the selected locale" do
    cookies[:locale] = "fr"

    get "/"

    assert_response :success
    assert_select "h1#home-title", "Trouvez votre prochain coup de cœur."
    assert_select "a.home-button[href='/store']", "Découvrir la boutique"
  end
end
