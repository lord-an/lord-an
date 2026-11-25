require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  setup { @user = User.take }

  test "new" do
    get "/authenticate/session/new"
    assert_response :success
    assert_select "form[action='/authenticate/session']"
  end

  test "authenticated users are redirected instead of seeing or submitting the login form" do
    sign_in_as @user
    other_user = User.where.not(id: @user.id).first
    session_count = other_user.sessions.count

    get "/authenticate/session/new"

    assert_redirected_to "/settings#account"

    post "/authenticate/session", params: {
      email_address: other_user.email_address,
      password: "password"
    }

    assert_redirected_to "/settings#account"
    assert_equal session_count, other_user.sessions.count

    get "/settings"
    assert_response :success
    assert_select "p.settings-card__value", @user.email_address
  end

  test "stale session cookies are cleared when the stored session is gone" do
    stored_session = @user.sessions.create!
    cookie_jar = ActionDispatch::TestRequest.create.cookie_jar
    cookie_jar.signed[Current::SESSION_COOKIE] = stored_session.id
    cookies[Current::SESSION_COOKIE.to_s] = cookie_jar[Current::SESSION_COOKIE]
    stored_session.destroy!

    get "/portal/settings"

    assert_redirected_to "/authenticate/session/new"
    assert_empty cookies[Current::SESSION_COOKIE]
  end

  test "host pages clear stale session cookies too" do
    stored_session = @user.sessions.create!
    cookie_jar = ActionDispatch::TestRequest.create.cookie_jar
    cookie_jar.signed[Current::SESSION_COOKIE] = stored_session.id
    cookies[Current::SESSION_COOKIE.to_s] = cookie_jar[Current::SESSION_COOKIE]
    stored_session.destroy!

    get "/"

    assert_response :success
    assert_empty cookies[Current::SESSION_COOKIE]
    assert_select "a[href='/authenticate/session/new']", "Log in"
  end

  test "create with valid credentials" do
    post "/authenticate/session", params: { email_address: @user.email_address, password: "password" }

    assert_redirected_to "/settings#account"
    assert cookies[Current::SESSION_COOKIE]
  end

  test "login restores the originally requested local path" do
    get "/portal/settings/edit"
    assert_redirected_to "/authenticate/session/new"

    post "/authenticate/session", params: { email_address: @user.email_address, password: "password" }

    assert_redirected_to "/portal/settings/edit"
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
