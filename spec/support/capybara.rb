# spec/support/capybara.rb
require "capybara/rspec"
require "securerandom"
require "tmpdir"

Capybara.server = :puma, { Silent: true }
Capybara.default_max_wait_time = 5

Capybara.register_driver :docker_chrome_headless do |app|
  opts = Selenium::WebDriver::Chrome::Options.new

  # ✅ テストごとにユニークなユーザーデータディレクトリを作成
  tmp_profile = Dir.mktmpdir("chrome-profile-")

  %W[
    headless=new
    no-sandbox
    disable-dev-shm-usage
    disable-gpu
    window-size=1400,1400
    remote-debugging-port=0        # ← ポート衝突回避（自動割当）
    user-data-dir=#{tmp_profile}   # ← ここが肝
    no-first-run
    no-default-browser-check
  ].each { |a| opts.add_argument(a) }

  # arm64 + Debian の Chromium 構成に対応（自動検出）
  chromium_bin = ["/usr/bin/chromium", "/usr/bin/chromium-browser"].find { |p| File.exist?(p) }
  opts.binary = chromium_bin if chromium_bin

  driver_path = ["/usr/bin/chromedriver", "/usr/lib/chromium/chromedriver"].find { |p| File.exist?(p) }
  service = Selenium::WebDriver::Service.chrome(path: driver_path) if driver_path

  Capybara::Selenium::Driver.new(app, browser: :chrome, options: opts, service: service)
end

Capybara.javascript_driver = :docker_chrome_headless
Capybara.default_driver    = :rack_test

RSpec.configure do |config|
  config.before(:each, type: :system, js: true)  { driven_by :docker_chrome_headless }
  config.before(:each, type: :system, js: false) { driven_by :rack_test }
end
