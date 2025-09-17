class GithubApp
  class InstallationMissing < StandardError; end

  def self.jwt
    private_key = OpenSSL::PKey::RSA.new(ENV.fetch("GITHUB_APP_PRIVATE_KEY").gsub("\\n", "\n"))
    payload = {
      iat: Time.now.to_i - 60,
      exp: Time.now.to_i + 9*60,
      iss: ENV.fetch("GITHUB_APP_ID").to_i
    }
    JWT.encode(payload, private_key, "RS256")
  end

  def self.installation_client(installation_id)
    app_client = Octokit::Client.new(bearer_token: jwt)
    app_client.installation(installation_id)
    token = app_client.create_app_installation_access_token(installation_id)[:token]
    Octokit::Client.new(access_token: token)
  rescue Octokit::NotFound
    return nil
  end
end
