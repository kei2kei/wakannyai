# frozen_string_literal: true
require "rails_helper"

RSpec.describe "Comments", type: :system, js: true do
  let(:author) { create(:user, :with_github_app, name: "著者") }
  let(:answer) { create(:user, name: "回答者") }
  let(:post_)  { create(:post, user: author, title: "Q", content: "本文") }

  # CodeMirror(EasyMDE) に値を入れるユーティリティ
  def set_easymde_value(scope, text)
    cm = scope.find(".CodeMirror", visible: :all, wait: 5)
    page.execute_script("arguments[0].CodeMirror.setValue(arguments[1])", cm, text)
  end

  it "コメントを投稿できる" do
    login_as(answer, scope: :user)
    visit post_path(post_)

    # ページ上の最初のコメント用フォームに入力
    set_easymde_value(page, "最初のコメントです")

    # そのまま最初に見える「投稿する」をクリック（＝新規コメントフォーム）
    click_on "投稿する"

    expect(page).to have_content "回答者：#{answer.name}"
    expect(page).to have_content "最初のコメントです"
  end

  it "返信を投稿できる" do
    parent = create(:comment, post: post_, user: answer, content: "親コメント")

    login_as(author, scope: :user)
    visit post_path(post_)

    # 親コメントブロックを特定して、その中の「返信」を押す
    parent_block = find(:xpath, %{//div[@data-controller="comment"][.//article[contains(., "親コメント")]]}, wait: 5)
    within(parent_block) { click_on "返信" }

    # 返信フォームコンテナが展開される（hidden解除）
    reply_container = parent_block.find('[data-comment-target="replyFormContainer"]', visible: :all, wait: 5)

    # 返信フォームのEasyMDEに入力して送信
    set_easymde_value(reply_container, "返信です")
    within(reply_container) { click_on "投稿する" }

    expect(page).to have_content "返信です"
  end

  it "著者は自身以外のコメントをベストアンサーに選べる" do
    _c2 = create(:comment, post: post_, user: author,  content: "自分のコメント") # 自分は対象外
    c1  = create(:comment, post: post_, user: answer,  content: "候補1")

    login_as(author, scope: :user)
    visit post_path(post_)

    target = find(:xpath, %{//div[@data-controller="comment"][.//article[contains(., "候補1")]]}, wait: 5)
    within(target) { click_on "ベストアンサーに選ぶ" }

    expect(page).to have_content "✨ ベストアンサー ✨"
  end
end
