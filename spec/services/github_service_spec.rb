require "ostruct"
require "rails_helper"

RSpec.describe GithubService do
  let(:user) do
    build(:user,
      name: "U",
      email: "u@example.com",
      github_app_installation_id: 123,
      github_repo_full_name: "owner/repo",
      github_branch: "main"
    )
  end

  let(:service) { described_class.new(user) }
  let(:client)  { double("Octokit::Client") }
  let(:post_rec) { create(:post, user: user, title: "タイトル!!", content: "本文です", created_at: Time.current, updated_at: Time.current) }

  before do
    allow(GithubApp).to receive(:installation_client).with(123).and_return(client)
  end

  context "正常系" do
    it "新規ファイルを作成して URL を返す" do
      allow(client).to receive(:contents).and_raise(Octokit::NotFound)
      allow(client).to receive(:create_contents).and_return(
        { content: { html_url: "https://github.com/owner/repo/blob/main/wakannyai_posts/title.md" } }.with_indifferent_access
      )

      result = service.sync_post!(post_rec)

      expect(result[:success]).to be true
      expect(result[:url]).to include("github.com/owner/repo")
    end

    it "既存ファイルを更新して URL を返す" do
      allow(client).to receive(:contents).and_return(OpenStruct.new(sha: "abc123"))
      allow(client).to receive(:update_contents).and_return(
        { content: { html_url: "https://github.com/owner/repo/blob/main/wakannyai_posts/title.md" } }.with_indifferent_access
      )

      result = service.sync_post!(post_rec)
      expect(result[:success]).to be true
    end
  end

  context "異常系" do
    it "アンインストール（InstallationMissing）ならフレンドリーに失敗" do
      allow(GithubApp).to receive(:installation_client).with(123).and_return(nil)

      result = service.sync_post!(post_rec)
      expect(result[:success]).to be false
      expect(result[:error]).to match(/アンインストール|再接続/)
    end

    it "Forbidden/Unauthorized なら権限不足のメッセージ" do
      client = instance_double(Octokit::Client)

      allow(GithubApp).to receive(:installation_client).with(123).and_return(client)
      allow(client).to receive(:repo).with("owner/repo")
        .and_return(OpenStruct.new(default_branch: "main"))
      allow(client).to receive(:contents).and_return(nil)

      allow(client).to receive(:create_contents).and_raise(Octokit::Forbidden)

      result = described_class.new(user).sync_post!(post_rec)

      expect(result[:success]).to be(false)
      expect(result[:error]).to include("権限")
    end

    it "NotFound（リポジトリなし）" do
      user = create(:user,
        name: "U", email: "u@example.com",
        github_app_installation_id: 123,
        github_repo_full_name: "owner/repo",
        github_branch: "main"
      )
      post_rec = create(:post, user: user, title: "タイトル!!", content: "本文です",
                        created_at: Time.current, updated_at: Time.current)

      client = instance_double(Octokit::Client)

      allow(GithubApp).to receive(:installation_client).with(123).and_return(client)

      allow(client).to receive(:contents).and_return(nil)

      allow(client).to receive(:create_contents).and_raise(Octokit::NotFound)

      result = GithubService.new(user).sync_post!(post_rec)

      expect(result[:success]).to be(false)
      expect(result[:error]).to match(/リポジトリが見つかりません|Not\s*Found/i)
    end
  end
end
