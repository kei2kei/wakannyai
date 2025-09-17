# frozen_string_literal: true
require "rails_helper"

RSpec.describe "Authorization", type: :system, js: true do
  let(:me)    { create(:user, :with_github_app, name: "Me") }
  let(:other) { create(:user, name: "Other") }

  it "他人の投稿では編集/削除/解決ボタンが出ない" do
    post = create(:post, user: other, title: "他人の投稿", content: "本文")
    login_as(me, scope: :user)

    visit post_path(post)
    expect(page).to have_content "タイトル：他人の投稿"
    expect(page).not_to have_link("編集")
    expect(page).not_to have_link("削除")
    expect(page).not_to have_button("解決した")
  end

  it "自分の未解決投稿は『解決した』ボタンで解決済みにできる" do
    post = create(:post, user: me, title: "自分の投稿", content: "本文", status: "unsolved")
    login_as(me, scope: :user)

    visit post_path(post)
    expect(page).to have_content "未解決"

    accept_confirm("この問題を解決済みにしますか？") { click_button "解決した" }

    expect(page).to have_content "解決済み"
    expect(page).not_to have_content "未解決"
  end
end
