# frozen_string_literal: true
require "rails_helper"

RSpec.describe "Login/Logout", type: :system, js: true do
  let(:user) { create(:user, :with_github_app, name: "Me") }

  it "未ログイン時はヘッダーに『ログイン』が出る" do
    visit root_path
    expect(page).to have_button("ログイン")
  end

  it "ログイン済みなら『ログアウト』が出て、押すと未ログイン状態になる" do
    login_as(user, scope: :user)

    visit root_path
    expect(page).to have_button("ログアウト")

    # Devise の destroy_user_session は button_to なので click_button でOK
    click_button "ログアウト"

    expect(page).to have_button("ログイン")
    # 「新規作成」は常時表示だが、ログイン必須ページへの遷移でガードも見られるならここで検証可
  end

  it "ログイン済みだと『新規作成』から投稿フォームに行ける" do
    login_as(user, scope: :user)
    visit root_path
    click_on "新規作成"
    expect(page).to have_content "新規作成"
    expect(page).to have_field "タイトル"
    expect(page).to have_field('markdown-editor', type: :textarea, visible: :all)
  end
end
