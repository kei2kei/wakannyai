# frozen_string_literal: true
require "rails_helper"

RSpec.describe "Comments", type: :system, js: true do
  let(:author) { create(:user, :github_authenticated, name: "著者") }
  let(:answer) { create(:user, name: "回答者") }
  let(:post_)  { create(:post, user: author, title: "Q", content: "本文") }

  it "コメントを投稿できる" do
    login_as(answer, scope: :user)
    visit post_path(post_)

    fill_in "コメントを書く", with: "最初のコメントです"
    click_on "投稿する"

    expect(page).to have_content "回答者：#{answer.name}"
    expect(page).to have_content "最初のコメントです"
  end

  it "返信を投稿できる" do
    comment = create(:comment, post: post_, user: answer, content: "親コメント")

    login_as(author, scope: :user)
    visit post_path(post_)

    # 親コメントブロック内の「返信」ボタンを押す
    find(:xpath, %{//div[@data-controller="comment"][.//p[contains(., "親コメント")]]//button[contains(., "返信")]}).click

    # ← ここが肝：そのコメントの中に reply-form が現れるまで待つ
    form = find(:xpath, %{//div[@data-controller="comment"][.//p[contains(., "親コメント")]]//form[contains(@class,"reply-form")]}, wait: 5)

    within(form) do
      find('textarea[name="comment[content]"]', visible: :all, wait: 5).set("返信です")
      click_on "投稿する"
    end

    expect(page).to have_content "返信です"
  end

  it "著者は自身以外のコメントをベストアンサーに選べる" do
    c1 = create(:comment, post: post_, user: answer, content: "候補1")
    c2 = create(:comment, post: post_, user: author, content: "自分のコメント") # 自分は対象外

    login_as(author, scope: :user)
    visit post_path(post_)

    target = find(:xpath, %{//div[@data-controller="comment"][.//p[contains(., "候補1")]]})
    within(target) { click_on "ベストアンサーに選ぶ" }

    expect(page).to have_content "✨ ベストアンサー ✨"
  end
end
