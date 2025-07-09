puts "Destroying existing data..."
Post.destroy_all
User.destroy_all

puts "Creating users and posts..."

# --- ユーザーの作成 ---
# パスワード関連のカラムがまだないため、nameとemailのみでユーザーを作成します。
# ログイン機能やパスワード設定は、関連カラムを後で追加してから実装します。
admin_user = User.create!(
  name: "管理者",
  email: "admin@example.com"
)
puts "Created User: #{admin_user.name} (#{admin_user.email})"

test_user1 = User.create!(
  name: "テストユーザー1",
  email: "test1@example.com"
)
puts "Created User: #{test_user1.name} (#{test_user1.email})"

test_user2 = User.create!(
  name: "テストユーザー2",
  email: "test2@example.com"
)
puts "Created User: #{test_user2.name} (#{test_user2.email})"


# --- 記事の作成とユーザーへの紐付け ---

# 前提: Postモデルにuser_idカラムがある必要があります。
# もしuser_idカラムがまだPostsテーブルにない場合は、このSeedファイルはエラーになります。
# その場合は、PostモデルとUserモデルのアソシエーション設定と、
# Postsテーブルへのuser_idカラム追加マイグレーションを先に行う必要があります。

# 管理者ユーザーが投稿する記事
admin_user.posts.create!(
  title: "管理者による最初の投稿",
  content: "これは管理者ユーザーが書いた最初の記事です。システム管理について。"
)
admin_user.posts.create!(
  title: "Rails開発のヒント",
  content: "Railsで効率的に開発するためのいくつかのヒントを紹介します。"
)

# テストユーザー1が投稿する記事
test_user1.posts.create!(
  title: "Docker環境構築の記録",
  content: "DockerとRailsを使った開発環境の構築手順をまとめました。多くのエラーを乗り越えて完成！"
)
test_user1.posts.create!(
  title: "初めてのマイグレーション",
  content: "Railsのマイグレーションでテーブルやカラムを操作する方法を学びました。NULL制約もこれで安心。"
)

# テストユーザー2が投稿する記事
test_user2.posts.create!(
  title: "デザインの重要性",
  content: "ブログのデザインを考えるのは難しいですが、ユーザー体験には不可欠です。"
)

# ループを使ってさらに多くの記事をランダムなユーザーに紐付けて作成する例
puts "Creating additional random posts..."
users = User.all # すべてのユーザーを取得
15.times do |i|
  random_user = users.sample # ランダムなユーザーを選択
  random_user.posts.create!(
    title: "自動生成記事 #{i+1} by #{random_user.name}",
    content: "これは#{random_user.name}が投稿した自動生成記事の#{i+1}番目です。テストデータとして利用します。"
  )
end

puts "Seed data created successfully!"