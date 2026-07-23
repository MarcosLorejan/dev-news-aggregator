# Be sure to restart your server when you modify this file.

# Content Security Policy for the React/Vite shell + same-origin Rails API.
# See https://guides.rubyonrails.org/security.html#content-security-policy-header
#
# Nonces are not required in production: Vite emits external module scripts and
# stylesheets under /vite (script-src/style-src 'self'). React style={{}} attributes
# need style-src 'unsafe-inline' (nonces do not cover style attributes).
# Enable a nonce_generator only if you add inline <script> tags or Vite refresh tags.
#
# CSP is skipped in development so Vite HMR (localhost:3036 / websockets) keeps working.

Rails.application.configure do
  next if Rails.env.development?

  config.content_security_policy do |policy|
    policy.default_src :self
    policy.font_src    :self, :data
    policy.img_src     :self, :https, :data
    policy.object_src  :none
    policy.script_src  :self
    policy.style_src   :self, :unsafe_inline
    policy.connect_src :self
    policy.worker_src  :self
    policy.base_uri    :self
    policy.form_action :self
    policy.frame_ancestors :none
  end
end
