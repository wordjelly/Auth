module OmniauthMacros
  MOCK_TOKEN = "mock_token"
  EXPIRES_AT = 20000
  ##########
  ##########
  ##########
  ########## USED IN EXTENSION SPECS.
  ##########
  ##########
  def mock_auth_hash(provider,token=nil,expires_at=nil,simulate_error=nil)
    if simulate_error
      OmniAuth.config.mock_auth[provider] = nil
    else
      token ||= 'mock_token'
      expires_at ||= 20000
      # The mock_auth configuration allows you to set per-provider (or default)
      # authentication hashes to return during integration testing.
      OmniAuth.config.mock_auth[provider] = OmniAuth::AuthHash.new({
        'provider' => provider.to_s,
        'uid' => '123545',
        'info' => {
          'name' => 'mockuser',
          'image' => 'mock_user_thumbnail_url',
          'email' => 'rrphotosoft@gmail.com'
        },
        'credentials' => {
          'token' => token,
          'secret' => 'mock_secret',
          'expires_at' => expires_at
        }
      })
    end
  end

  #########
  #########
  ######### USED IN EXTENSION SPECS
  #########
  #########
  def mock_defective_auth_hash
    nil
  end

############################ THESE ARE USED IN OMNIAUTH_CALLBACK_REQUEST_SPECS.


  ##USED TO SIMULATE ERROR IN OMNI_CONCERN.
  def google_oauth2_nil_hash
      OmniAuth::Strategies::GoogleOauth2.class_eval do 
          ##########
          ##JUST MODIFIED THIS TO RETURN NIL AS AUTH_HASH, SO THAT AN ERROR IS SIMULATED IN THE OMNI_COMMON DEF
          def auth_hash
              nil
          end

          ##########
          ##JUST MODIFIED THIS TO RETURN TRUE EVERYWHERE.
          private
          def verify_id_token(id_token)
              puts "called verify id token."
              true
          end

          def verify_hd(access_token)
              puts "Called verify hd."
              true
          end 
      end
  end

  
  def google_oauth2_verify_token_true_verify_hd_true

      OmniAuth::Strategies::GoogleOauth2.class_eval do 
          ##########
          ##JUST MODIFIED THIS TO RETURN THE GOOGLE_OAUTH2 AUTH HASH.
          def auth_hash
              OmniAuth::AuthHash.new({
                'provider' => 'google_oauth2',
                'uid' => '12345',
                'info' => {
                  'name' => 'mockuser',
                  'image' => 'mock_user_thumbnail_url',
                  'email' => 'rrphotosoft@gmail.com'
                },
                'credentials' => {
                  'token' => OmniauthMacros::MOCK_TOKEN,
                  'secret' => 'mock_secret',
                  'expires_at' => OmniauthMacros::EXPIRES_AT
                }
              })
          end

          ##########
          ##JUST MODIFIED THIS TO RETURN TRUE EVERYWHERE.
          private
          def verify_id_token(id_token)
              true
          end

          def verify_hd(access_token)
              true
          end 
      end
  end


  def google_oauth2_verify_hd_true

      OmniAuth::Strategies::GoogleOauth2.class_eval do 
          ##########
          ##JUST MODIFIED THIS TO RETURN THE GOOGLE_OAUTH2 AUTH HASH.
          def auth_hash
              OmniAuth::AuthHash.new({
                'provider' => 'google_oauth2',
                'uid' => '12345',
                'info' => {
                  'name' => 'mockuser',
                  'image' => 'mock_user_thumbnail_url',
                  'email' => 'rrphotosoft@gmail.com'
                },
                'credentials' => {
                  'token' => OmniauthMacros::MOCK_TOKEN,
                  'secret' => 'mock_secret',
                  'expires_at' => OmniauthMacros::EXPIRES_AT
                }
              })
          end

          ##########
          ##JUST MODIFIED THIS TO RETURN TRUE EVERYWHERE.
          private
          def verify_hd(access_token)
              true
          end 
      end
  end

  def google_oauth2_auth_code_get_token

    OAuth2::Strategy::AuthCode.class_eval do 
        def get_token(code, params = {}, opts = {})
            ::OAuth2::AccessToken.new(@client,"")
        end
    end

  end




  def facebook_oauth2_verify_fb_ex_token
      OmniAuth::Strategies::Facebook.class_eval do 
          def auth_hash
              OmniAuth::AuthHash.new({
                'provider' => 'facebook',
                'uid' => '12345',
                'info' => {
                  'name' => 'mockuser',
                  'image' => 'mock_user_thumbnail_url',
                  'email' => 'rrphotosoft@gmail.com'
                },
                'credentials' => {
                  'token' => OmniauthMacros::MOCK_TOKEN,
                  'secret' => 'mock_secret',
                  'expires_at' => OmniauthMacros::EXPIRES_AT
                }
              })
          end
          
          private
          def verify_exchange_token(exchange_token)
              ::OAuth2::AccessToken.new(client,"")
          end 
      end

  end

  def facebook_oauth2_nil_hash

    OmniAuth::Strategies::Facebook.class_eval do 
          def auth_hash
              nil
          end
          
          private
          def verify_exchange_token(exchange_token)
              ::OAuth2::AccessToken.new(client,"")
          end 
      end    

  end


end
