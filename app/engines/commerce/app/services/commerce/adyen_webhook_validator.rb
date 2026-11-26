require "base64"
require "openssl"

module Commerce
  class AdyenWebhookValidator
    class Error < StandardError; end

    def valid?(notification)
      signature = notification.dig("additionalData", "hmacSignature")
      return false if signature.blank?

      encoded_key = ENV.fetch("ADYEN_HMAC_KEY")
      return false unless encoded_key.match?(/\A[0-9a-f]{64}\z/i)

      key = [ encoded_key ].pack("H*")

      expected = Base64.strict_encode64(OpenSSL::HMAC.digest("SHA256", key, signing_string(notification)))
      ActiveSupport::SecurityUtils.secure_compare(expected, signature)
    rescue ArgumentError, KeyError
      false
    end

    private
      def signing_string(notification)
        amount = notification["amount"] || {}
        %w[ pspReference originalReference merchantAccountCode merchantReference ].map { |key| notification[key].to_s }.push(
          amount["value"].to_s,
          amount["currency"].to_s,
          notification["eventCode"].to_s,
          notification["success"].to_s
        ).join(":")
      end
  end
end
