# frozen_string_literal: true
require "rails_helper"

RSpec.describe "Navigation & Search", type: :system, js: true do
  let(:user) { create(:user, :github_authenticated) }

  it "検索フォームで絞り込める（タイトル/本文/タグ）" do
    login_as(user, scope: :user)
    create(:post, user:, title: "Docker入門",  content: "compose")
    create(:post, user:, title: "Railsガイド", content: "ActiveRecord")

    visit root_path
    fill_in 'q[title_or_content_or_tags_name_cont]', with: "Rails"
    click_on "検索"

    expect(page).to have_content "Railsガイド"
    expect(page).not_to have_content "Docker入門"
  end

  it "マイポスト：未投稿→空表示、作成後は表示" do
    login_as(user, scope: :user)

    visit posts_my_posts_path
    expect(page).to have_content "まだ投稿がありません。"

    create(:post, user:, title: "私の投稿")
    visit posts_my_posts_path
    expect(page).to have_content "私の投稿"
  end
end
