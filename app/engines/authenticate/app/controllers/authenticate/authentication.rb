module Authenticate
  module Authentication
    extend ActiveSupport::Concern

    included do
      before_action :require_authentication
      helper_method :authenticated?
    end

    class_methods do
      def allow_unauthenticated_access(**options)
        skip_before_action :require_authentication, **options
      end
    end

    private
      def authenticated?
        resume_session
      end

      def require_authentication
        resume_session || request_authentication
      end

      def resume_session
        return unless defined?(::Current) && defined?(::Session)

        Current.session ||= ::Current.session_from(cookies)
      end

      def request_authentication
        session[:return_to_after_authenticating] = request.fullpath
        redirect_to "/authenticate/session/new"
      end

      def after_authentication_url
        requested_path = session.delete(:return_to_after_authenticating).to_s
        return requested_path if safe_return_path?(requested_path)

        "/settings#account"
      end

      def redirect_authenticated_user
        redirect_to "/settings#account" if authenticated?
      end

      def safe_return_path?(path)
        path.start_with?("/") && !path.start_with?("//") && !path.include?("\\")
      end

      def start_new_session_for(user)
        reset_session
        user.sessions.create!(user_agent: request.user_agent, ip_address: request.remote_ip).tap do |new_session|
          Current.session = new_session
          cookies.signed.permanent[::Current::SESSION_COOKIE] = {
            value: new_session.id,
            httponly: true,
            same_site: :lax
          }
        end
      end

      def terminate_session
        Current.session.destroy if defined?(::Current) && Current.session
        Current.session = nil
        cookies.delete(::Current::SESSION_COOKIE)
        cookies.delete(:session_id)
      end
  end
end
