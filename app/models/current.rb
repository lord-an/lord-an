class Current < ActiveSupport::CurrentAttributes
  SESSION_COOKIE = :lord_an_session_id

  attribute :session
  delegate :user, to: :session, allow_nil: true
end
