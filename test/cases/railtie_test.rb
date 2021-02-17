require 'rails'
require 'global_id/railtie'
require 'active_support/testing/isolation'


module BlogApp
  class Application < Rails::Application; end
end

class RailtieTest < ActiveSupport::TestCase
  include ActiveSupport::Testing::Isolation

  def setup
    Rails.env = 'development'
    @app = BlogApp::Application.send(:new)
    @app.config.eager_load = false
    @app.config.logger = Logger.new(nil)
    @app.config.secret_token = ('x' * 30)
  end

  test 'GlobalID.app for Blog::Application defaults to blog' do
    @app.initialize!
    assert_equal 'blog-app', GlobalID.app
  end

  test 'GlobalID.app can be set with config.global_id.app =' do
    @app.config.global_id.app = 'foo'
    @app.initialize!
    assert_equal 'foo', GlobalID.app
  end

  test 'SignedGlobalID.expires_in can be explicitly set to nil with config.global_id.expires_in' do
    @app.config.global_id.expires_in = nil
    @app.initialize!
    assert_nil SignedGlobalID.expires_in
  end

  test 'SignedGlobalID.verifier defaults to Blog::Application.message_verifier(:signed_global_ids) when secret_token is present' do  
    @app.initialize!  
    message = {id: 42}  
    signed_message = SignedGlobalID.verifier.generate(message) 

    generated_key = OpenSSL::PKCS5.pbkdf2_hmac_sha1(@app.config.secret_token, 'signed_global_ids', 1000, 64)
    assert_equal ActiveSupport::MessageVerifier.new(generated_key).generate(message), signed_message
  end

  test 'SignedGlobalID.verifier defaults to nil when secret_token is not present' do
    original_env, Rails.env = Rails.env, 'production'

    begin
      @app.config.secret_token = nil
      @app.initialize!
      assert_nil SignedGlobalID.verifier
    ensure
      Rails.env = original_env
    end
  end

  test 'SignedGlobalID.verifier can be set with config.global_id.verifier =' do
    custom_verifier = @app.config.global_id.verifier = ActiveSupport::MessageVerifier.new('muchSECRETsoHIDDEN', serializer: SERIALIZER)
    @app.initialize!
    message = {id: 42}
    signed_message = SignedGlobalID.verifier.generate(message)
    assert_equal custom_verifier.generate(message), signed_message
  end

end
