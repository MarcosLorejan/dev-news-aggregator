module MutatingAuthentication
  extend ActiveSupport::Concern

  private

  def authenticate_mutation!
    return unless mutating_auth_configured?

    username = ENV.fetch("MUTATING_AUTH_USERNAME")
    password = ENV.fetch("MUTATING_AUTH_PASSWORD")

    authenticated = authenticate_with_http_basic do |user, pass|
      secure_credential_match?(user, username) && secure_credential_match?(pass, password)
    end

    return if authenticated

    response.set_header("WWW-Authenticate", 'Basic realm="Dev News Aggregator"')
    render json: { error: "Unauthorized" }, status: :unauthorized
  end

  def mutating_auth_configured?
    ENV["MUTATING_AUTH_USERNAME"].present? && ENV["MUTATING_AUTH_PASSWORD"].present?
  end

  def secure_credential_match?(provided, expected)
    ActiveSupport::SecurityUtils.secure_compare(
      Digest::SHA256.hexdigest(provided.to_s),
      Digest::SHA256.hexdigest(expected.to_s)
    )
  end
end
