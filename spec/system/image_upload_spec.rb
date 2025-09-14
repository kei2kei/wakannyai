# frozen_string_literal: true
# spec/system/image_upload_spec.rb
require "rails_helper"

RSpec.describe "画像アップロード（エディタ統合）", type: :system, js: true do
  let(:user) { create(:user, :github_authenticated) }

  it "ツールバー経由でアップ→プレビュー表示→保存できる" do
    login_as(user, scope: :user)
    visit new_post_path

    find(".editor-toolbar .fa-upload", wait: 5).click

    # Stimulus が挿した input を掴む
    page.find('input.test-upload-input', visible: :all, wait: 5)
        .set(Rails.root.join("spec/fixtures/files/sample.jpg"))

    # プレビューに <img> が出る（/blobs でも OK）
    expect(page).to have_css('#preview-container img[src^="/rails/active_storage/"]', wait: 15)

    # hidden の images[] が仕込まれている
    expect(page).to have_css('input[type="hidden"][name="post[images][]"]', visible: :all)

    fill_in "タイトル", with: "画像付き投稿"
    click_button "保存"

    # 詳細画面でも画像が出ている
    expect(page).to have_content("画像付き投稿")
    expect(page).to have_css("article img", wait: 10)
  end
end
