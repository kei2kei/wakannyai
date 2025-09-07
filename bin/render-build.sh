#!/usr/bin/env bash
set -o errexit

bundle install

# JS を使っている場合（EasyMDE/Tagify など）
if command -v yarn >/dev/null 2>&1; then
  yarn install --frozen-lockfile || true
fi

bundle exec rails assets:precompile
bundle exec rails assets:clean

# Freeプランでは preDeploy が使えないため、build 中に migrate を実行するのが推奨
bundle exec rails db:migrate
