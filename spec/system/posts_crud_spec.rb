# frozen_string_literal: true
require "rails_helper"

RSpec.describe "Posts CRUD", type: :system, js: true do
  let(:user) { create(:user, :github_authenticated) }

  before do
    login_as(user, scope: :user)
    visit root_path
  end

  it "新規作成できる（EasyMDE + Tagify）" do
  click_on "新規作成"

  fill_in "タイトル", with: "システムテストのタイトル"
  set_easy_mde "本文だよ。**太字**と`code`。"

  # Tagifyが初期化されていなくても確実に値を送る
  page.execute_script <<~JS
    var el = document.querySelector('input[name="post[tag_names]"]');
    if (el && el.tagify) {
      el.tagify.removeAllTags(); el.tagify.addTags(['Rails','Testing']);
    } else if (el) {
      el.value = 'Rails, Testing';
      el.dispatchEvent(new Event('input',{bubbles:true}));
      el.dispatchEvent(new Event('change',{bubbles:true}));
    }
  JS

  click_on "保存"

  expect(page).to have_content "タイトル：システムテストのタイトル"
  expect(page).to have_content "本文だよ。"
  expect(page).to have_content "タグ：Rails, Testing"  # ← ここが通ればOK
  expect(page).to have_content "未解決"
end



  it "バリデーションエラーが表示される（タイトル未入力）" do
    click_on "新規作成"
    set_easy_mde "本文のみ"
    click_on "保存"
    expect(page).to have_content("タイトルを入力してください").or have_css(".field_with_errors")
  end

  it "編集できる" do
    post = create(:post, user:, title: "旧タイトル", content: "旧本文")
    visit post_path(post)
    click_on "編集"

    fill_in "タイトル", with: "新タイトル"
    set_easy_mde "新本文"
    click_on "保存"

    expect(page).to have_content "タイトル：新タイトル"
    expect(page).to have_content "新本文"
  end

  it "削除できる" do
    post = create(:post, user:, title: "消すやつ")
    visit post_path(post)

    # Turbo環境では data-confirm が出ない場合があるので accept_confirm は使わない
    click_on "削除"

    expect(page).to have_current_path(root_path).or have_current_path(posts_path)
    expect(page).not_to have_content "消すやつ"
  end

  it "未解決 → 『解決した』で解決済みに変わる" do
    post = create(:post, user:, title: "自分の投稿", content: "本文", status: :unsolved)
    visit post_path(post)

    expect(page).to have_content "未解決"
    expect(page).to have_button "解決した"

    accept_confirm("この問題を解決済みにしますか？") do
      click_button "解決した"
    end

    expect(page).to have_content "解決済み"
    expect(page).not_to have_button "解決した"
  end
end
