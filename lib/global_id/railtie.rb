begin
require 'rails/railtie'
rescue LoadError
else
require 'global_id'
require 'active_support'
require 'active_support/core_ext/string/inflections'
require 'active_support/core_ext/integer/time'

class GlobalID
  # = GlobalID Railtie
  # Set up the signed GlobalID verifier and include Active Record support.
  class Railtie < Rails::Railtie # :nodoc:
    config.global_id = ActiveSupport::OrderedOptions.new

    ['global_id/global_id', 'global_id/locator', 'global_id/signed_global_id', 'global_id/verifier'].each { |file| require file }

    initializer 'global_id' do |app|
      default_expires_in = 1.month
      default_app_name = app.railtie_name.gsub('_application', '').dasherize

      GlobalID.app = app.config.global_id.app ||= default_app_name
      SignedGlobalID.expires_in = app.config.global_id.fetch(:expires_in, default_expires_in)

      config.after_initialize do
        GlobalID.app = app.config.global_id.app ||= default_app_name
        SignedGlobalID.expires_in = app.config.global_id.fetch(:expires_in, default_expires_in)

        app.config.global_id.verifier ||= begin
          if app.config.secret_token
            generated_key = OpenSSL::PKCS5.pbkdf2_hmac_sha1(app.config.secret_token, 'signed_global_ids', 1000, 64)
            GlobalID::Verifier.new(generated_key)
          end
        rescue ArgumentError
          nil
        end
        SignedGlobalID.verifier = app.config.global_id.verifier
      end

      ActiveSupport.on_load(:active_record) do
        require 'global_id/identification'
        send :include, GlobalID::Identification
      end
    end
  end
end

end
