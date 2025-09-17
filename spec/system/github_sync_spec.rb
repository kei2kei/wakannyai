# frozen_string_literal: true
require "rails_helper"

RSpec.describe "GitHub同期", type: :system, js: true do
  let(:author) { create(:user, name: "Test User", email: "u@example.com") }

  before do
    login_as(author, scope: :user)
  end

  context "同期成功" do
    it "同期成功でフラッシュ表示" do
      # App連携が整っているユーザーにする
      author.update!(
        github_app_installation_id: 123,
        github_repo_full_name: "owner/repo",
        github_branch: "main"
      )
      post = create(:post, user: author, title: "同期テスト", content: "本文", created_at: Time.current, updated_at: Time.current)

      # Octokitクライアントのスタブ
      client = instance_double(Octokit::Client)
      allow(GithubApp).to receive(:installation_client).with(123).and_return(client)

      # 新規作成フローに入るため contents は nil
      allow(client).to receive(:contents).with("owner/repo", hash_including(path: /wakannyai_posts/)).and_return(nil)

      # create_contents が正しく呼ばれ、URLを返す
      allow(client).to receive(:create_contents)
        .and_return({ content: { html_url: "https://github.com/owner/repo/blob/main/wakannyai_posts/post.md" } })

      visit post_path(post)
      click_button "GitHubに同期"

      expect(page).to have_current_path(post_path(post), ignore_query: true, wait: 5)
      expect(page).to have_content("GitHubに同期しました").or have_content("同期しました")
      # show にリンク表示されていればより安心
      expect(page).to have_link("GitHubで見る")
    end
  end

  context "連携未設定" do
    it "導線を出し、同期ボタンは出さない" do
      # 連携未設定（ボタンが出ないのが正しい）
      author.update!(github_app_installation_id: nil, github_repo_full_name: nil)
      post = create(:post, user: author, title: "同期テスト", content: "本文")

      visit post_path(post)

      # インストール導線（リンク or ボタン）の存在
      expect(page).to(
        have_link("GitHub App をインストール").or have_button("GitHub App をインストール")
      )

      # 同期ボタンは出ない
      expect(page).not_to have_button("GitHubに同期")
    end
  end

  context "権限不足や404等" do
    it "権限不足/NotFound ならエラーフラッシュ表示" do
      author.update!(
        github_app_installation_id: 123,
        github_repo_full_name: "owner/repo",
        github_branch: "main"
      )
      post = create(:post, user: author, title: "同期テスト", content: "本文", created_at: Time.current, updated_at: Time.current)

      client = instance_double(Octokit::Client)
      allow(GithubApp).to receive(:installation_client).with(123).and_return(client)

      # 新規作成フロー（contents は nil）
      allow(client).to receive(:contents).and_return(nil)

      # パターンA）リポジトリ未発見
      allow(client).to receive(:create_contents).and_raise(Octokit::NotFound)

      visit post_path(post)
      click_button "GitHubに同期"

      expect(page).to have_current_path(post_path(post), ignore_query: true, wait: 5)
      expect(page).to have_content("同期に失敗").or have_content("リポジトリが見つかりません").or have_content("権限")
    end
  end
end
