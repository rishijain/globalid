require 'active_support'
require 'active_support/message_verifier'

class GlobalID
  class Verifier < ActiveSupport::MessageVerifier
    # https://github.com/rails/rails/blob/5-0-stable/activesupport/lib/active_support/message_verifier.rb#L115-L117
    def generate(value)
      data = encode(@serializer.dump(value))
      "#{data}--#{generate_digest(data)}"
    end

    # https://github.com/rails/rails/blob/5-0-stable/activesupport/lib/active_support/message_verifier.rb#L104-L106
    def verify(signed_message)
      verified(signed_message) || raise(InvalidSignature)
    end

    # https://github.com/rails/rails/blob/5-0-stable/activesupport/lib/active_support/message_verifier.rb#L52-L57
    def valid_message?(signed_message)
      return if signed_message.nil? || !signed_message.valid_encoding? || signed_message.blank?

      data, digest = signed_message.split("--".freeze)
      data.present? && digest.present? && secure_compare(digest, generate_digest(data))
    end

    # https://github.com/rails/rails/blob/5-0-stable/activesupport/lib/active_support/message_verifier.rb#L80-L90
    def verified(signed_message)
      if valid_message?(signed_message)
        begin
          data = signed_message.split("--".freeze)[0]
          @serializer.load(decode(data))
        rescue ArgumentError => argument_error
          return if argument_error.message =~ %r{invalid base64}
          raise
        end
      end
    end

    private
      def encode(data)
        ::Base64.urlsafe_encode64(data)
      end

      def decode(data)
        ::Base64.urlsafe_decode64(data)
      end
  end
end
