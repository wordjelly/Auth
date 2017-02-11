module OmniauthMacros
  def mock_auth_hash(token=nil,expires_at=nil,simulate_error=nil)
    if simulate_error
      OmniAuth.config.mock_auth[:google_oauth2] = nil
    else
      token ||= 'mock_token'
      expires_at ||= 20000
      # The mock_auth configuration allows you to set per-provider (or default)
      # authentication hashes to return during integration testing.
      OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new({
        'provider' => 'google_oauth2',
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

  def mock_defective_auth_hash
    nil
  end



  def mock_auth_hash_facebook
    # The mock_auth configuration allows you to set per-provider (or default)
    # authentication hashes to return during integration testing.
    OmniAuth.config.mock_auth[:facebook] = OmniAuth::AuthHash.new({
      'provider' => 'facebook',
      'uid' => 'abcde',
      'info' => {
        'name' => 'mockuser',
        'image' => 'mock_user_thumbnail_url',
        'email' => 'rrphotosoft@gmail.com'
      },
      'credentials' => {
        'token' => 'mock_token',
        'secret' => 'mock_secret',
        'expires_at' => 20000
      }
    })
  end
end
