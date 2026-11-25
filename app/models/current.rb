class Current < ActiveSupport::CurrentAttributes
  SESSION_COOKIE = :lord_an_session_id

  attribute :session
  delegate :user, to: :session, allow_nil: true

  def self.session_from(cookie_jar)
    cookie_jar.delete(:session_id)
    session_id = cookie_jar.signed[SESSION_COOKIE]
    return unless session_id

    ::Session.find_by(id: session_id).tap do |stored_session|
      cookie_jar.delete(SESSION_COOKIE) unless stored_session
    end
  end
end
