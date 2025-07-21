import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="tag-suggest"
export default class extends Controller {
  static targets = ["input", "searchResult"];
  connect() {
    console.log("TagSuggestControllerに接続!");
  }

  async searchTags() {
    console.log("検索開始!");
    // view側で指定したリクエスト先のURL
    const requestURL = this.data.get("searchUrl");
    // selectエレメント
    const tagElement = this.searchResultTarget;
    // イベント発火時に前のイベント時に保有していたリストを削除
    while (tagElement.firstChild) {
      tagElement.removeChild(tagElement.firstChild);
    }
    // ユーザーの入力値を元にSQLの後方一致を検索しにいくためのクエリ
    const queryParams = {
      query: this.inputTarget.value,
    };

    const requestParams = new URLSearchParams(queryParams);
    const response = await fetch(`${requestURL}?${requestParams}`);
    const data = await response.json();
    for (let tag of data) {
      const newTag = document.createElement("option");
      newTag.value = tag.id;
      newTag.textContent = tag.name;
      tagElement.appendChild(newTag);
    }
  }
}
