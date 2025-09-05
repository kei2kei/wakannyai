// app/javascript/controllers/cat_animator_controller.js

import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  // HTMLからdata-cat-animator-level-valueを受け取る
  static values = {
    level: Number,
    color: String,
    actions: Array
  };

  connect() {
    console.log('🚀 Cat Animator Connected! Level:', this.levelValue);
    this.currentAnimationTimeout = null;
    this.currentAnimationClass = null;

    // 💡 CSSアニメーションがすでにHTMLに適用されている場合は、それを削除して新しいアニメーションを開始
    this.element.classList.remove('cat-sit', 'cat-run', 'cat-walk', 'cat-laying-down');
    this.startAnimation();
  }

  disconnect() {
    // 💡 コントローラーが切断された際に、タイマーをクリアしてメモリリークを防ぐ
    if (this.currentAnimationTimeout) {
      clearTimeout(this.currentAnimationTimeout);
    }
    this.element.classList.remove(this.currentAnimationClass);
  }

  startAnimation() {
    const availableAnimations = this.getAvailableAnimations();

    // 💡 利用可能なアニメーションがない場合はログを出して終了
    if (availableAnimations.length === 0) {
      console.warn("No animations available for cat level:", this.levelValue);
      return;
    }

    // 現在のアニメーションクラスを削除
    if (this.currentAnimationClass) {
      this.element.classList.remove(this.currentAnimationClass);
    }

    // ランダムにアニメーションを選択
    const randomIndex = Math.floor(Math.random() * availableAnimations.length);
    const nextAnimationClass = availableAnimations[randomIndex];
    this.currentAnimationClass = nextAnimationClass;

    // 新しいアニメーションクラスを追加
    this.element.classList.add(nextAnimationClass);

    // 💡 CSSからアニメーションの継続時間とディレイを取得し、次をスケジュール
    const computedStyle = window.getComputedStyle(this.element);
    const animationDuration = parseFloat(computedStyle.getPropertyValue('animation-duration'));
    const animationDelay = parseFloat(computedStyle.getPropertyValue('animation-delay'));

    // アニメーション時間 + 0〜2秒のランダムな待機時間後に次のアニメーションを開始
    this.currentAnimationTimeout = setTimeout(() => {
      this.startAnimation();
    }, (animationDuration + animationDelay) * 1000 + Math.random() * 2000);
  }

  // レベルに応じて利用可能なアニメーションを返す
  getAvailableAnimations() {
    const level = this.levelValue;
    const animations = [];

    // レベル1: 'sit' と 'walk' は常に利用可能
    animations.push("cat-laying-down");
    

    // レベルに応じて動きを追加
    if (level >= 2) {
      animations.push("cat-walk");
    }
    if (level >= 3) {
      animations.push("cat-sit");
    }
    if (level >= 4) {
      animations.push("cat-run");
    }

    return animations;
  }
}