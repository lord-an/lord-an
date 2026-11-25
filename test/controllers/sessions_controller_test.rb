require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  setup { @user = User.take }

  test "new" do
    get "/authenticate/session/new"
    assert_response :success
  end

  test "create with valid credentials" do
    post "/authenticate/session", params: { email_address: @user.email_address, password: "password" }

    assert_redirected_to "/settings#account"
    assert cookies[Current::SESSION_COOKIE]
  end

  test "create with invalid credentials" do
    post "/authenticate/session", params: { email_address: @user.email_address, password: "wrong" }

    assert_redirected_to "/authenticate/session/new"
    assert_nil cookies[Current::SESSION_COOKIE]
  end

  test "destroy" do
    sign_in_as(User.take)

    delete "/authenticate/session"

    assert_redirected_to "/authenticate/session/new"
    assert_empty cookies[Current::SESSION_COOKIE]
  end

  test "legacy session cookies do not authenticate against host session ids" do
    legacy_cookie_jar = ActionDispatch::TestRequest.create.cookie_jar
    legacy_cookie_jar.signed[:session_id] = @user.sessions.create!.id
    cookies["session_id"] = legacy_cookie_jar[:session_id]

    get "/portal/settings"

    assert_redirected_to "/authenticate/session/new"
    assert_nil cookies[Current::SESSION_COOKIE]
    assert_empty cookies[:session_id]
  end
end
