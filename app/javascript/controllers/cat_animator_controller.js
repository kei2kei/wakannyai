import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static values = {
    level: Number,
    color: String
  };

  connect() {
    console.log('🚀 Cat Animator Connected! Level:', this.levelValue);
    this.currentAnimationTimeout = null;
    this.currentAnimationClass = null;

    this.element.classList.remove('cat-sit', 'cat-run', 'cat-walk', 'cat-laying-down');
    this.startAnimation();
  }

  disconnect() {
    if (this.currentAnimationTimeout) {
      clearTimeout(this.currentAnimationTimeout);
    }
    this.element.classList.remove(this.currentAnimationClass);
  }

  startAnimation() {
    const availableAnimations = this.getAvailableAnimations();

    if (availableAnimations.length === 0) {
      console.warn("No animations available for cat level:", this.levelValue);
      return;
    }

    if (this.currentAnimationClass) {
      this.element.classList.remove(this.currentAnimationClass);
    }

    const randomIndex = Math.floor(Math.random() * availableAnimations.length);
    const nextAnimationClass = availableAnimations[randomIndex];
    this.currentAnimationClass = nextAnimationClass;

    this.element.classList.add(nextAnimationClass);

    const computedStyle = window.getComputedStyle(this.element);
    const animationDuration = parseFloat(computedStyle.getPropertyValue('animation-duration'));
    const animationDelay = parseFloat(computedStyle.getPropertyValue('animation-delay'));

    this.currentAnimationTimeout = setTimeout(() => {
      this.startAnimation();
    }, (animationDuration + animationDelay) * 1000 + Math.random() * 2000);
  }

  getAvailableAnimations() {
    const level = this.levelValue;
    const animations = [];

    animations.push("cat-laying-down");

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