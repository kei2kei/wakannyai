# frozen_string_literal: true
require "rails_helper"

RSpec.describe "画像アップロード（エディタ統合）", type: :system, js: true do
  let(:user) { create(:user, :with_github_app) }

  before do
    # Warden login helper 有効
    Warden.test_mode!
  end

  it "ツールバー経由でアップ→プレビュー表示→保存できる" do
    login_as(user, scope: :user)
    visit new_post_path

    # EasyMDEツールバーのアップロードアイコンをクリック
    find(".editor-toolbar .fa-upload", wait: 5).click

    # Stimulus が動的に挿した input を掴む（class があればそれを、無ければ type=file で拾う）
    input = page.first('input.test-upload-input', visible: :all)
    input ||= page.find('input[type="file"]', visible: :all, wait: 5)

    input.set(Rails.root.join("spec/fixtures/files/sample.jpg"))

    # プレビューに <img> が出る（ActiveStorageの /rails/active_storage/〜 を含む）
    expect(page).to have_css('#preview-container img[src^="/rails/active_storage/"]', wait: 20)

    # hidden の images[] が同期されている（送信対象になる）
    expect(page).to have_css('input[type="hidden"][name="post[images][]"]', visible: :all)

    # タイトル入れて保存
    fill_in "タイトル", with: "画像付き投稿"
    click_button "保存"

    # 詳細画面でも画像が出ている
    expect(page).to have_content("画像付き投稿")
    expect(page).to have_css("article img", wait: 10)
  end
end
