require "test_helper"

class PasswordsControllerTest < ActionDispatch::IntegrationTest
  setup { @user = User.take }

  test "new" do
    get "/authenticate/passwords/new"
    assert_response :success
  end

  test "authenticated users are redirected away from password recovery" do
    sign_in_as @user

    get "/authenticate/passwords/new"

    assert_redirected_to "/settings#account"

    post "/authenticate/passwords", params: { email_address: @user.email_address }

    assert_redirected_to "/settings#account"
    assert_enqueued_emails 0
  end

  test "create" do
    post "/authenticate/passwords", params: { email_address: @user.email_address }
    assert_enqueued_email_with Authenticate::PasswordsMailer, :reset, args: [ @user ]
    assert_redirected_to "/authenticate/session/new"

    follow_redirect!
    assert_notice "reset instructions sent"
  end

  test "create for an unknown user redirects but sends no mail" do
    post "/authenticate/passwords", params: { email_address: "missing-user@example.com" }
    assert_enqueued_emails 0
    assert_redirected_to "/authenticate/session/new"

    follow_redirect!
    assert_notice "reset instructions sent"
  end

  test "edit" do
    get "/authenticate/passwords/#{@user.generate_token_for(:password_reset)}/edit"
    assert_response :success
  end

  test "edit with invalid password reset token" do
    get "/authenticate/passwords/invalid-token/edit"
    assert_redirected_to "/authenticate/passwords/new"

    follow_redirect!
    assert_notice "reset link is invalid"
  end

  test "update" do
    assert_changes -> { @user.reload.password_digest } do
      put "/authenticate/passwords/#{@user.generate_token_for(:password_reset)}",
        params: { password: "a secure new password", password_confirmation: "a secure new password" }
      assert_redirected_to "/authenticate/session/new"
    end

    follow_redirect!
    assert_notice "Password has been reset"
  end

  test "update with non matching passwords" do
    token = @user.generate_token_for(:password_reset)
    assert_no_changes -> { @user.reload.password_digest } do
      put "/authenticate/passwords/#{token}",
        params: { password: "a secure new password", password_confirmation: "a different password" }
      assert_redirected_to "/authenticate/passwords/#{token}/edit"
    end

    follow_redirect!
    assert_notice "match"
  end

  test "update rejects passwords below the minimum length" do
    token = @user.generate_token_for(:password_reset)

    assert_no_changes -> { @user.reload.password_digest } do
      put "/authenticate/passwords/#{token}",
        params: { password: "short", password_confirmation: "short" }
      assert_redirected_to "/authenticate/passwords/#{token}/edit"
    end

    follow_redirect!
    assert_notice "too short"
  end

  private
    def assert_notice(text)
      assert_select "div", /#{text}/
    end
end
