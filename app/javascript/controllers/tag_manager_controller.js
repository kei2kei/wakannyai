import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="tag-manager"
export default class extends Controller {
  static targets = ["input", "searchResult", "tagListContainer", "hiddenInput"];
  connect() {
    console.log("TagManagerControllerに接続!");
    this.selectedTags = (this.hiddenInputTarget.value?.trim() || '').split(',').map(str => str.trim()).filter(tag => tag.length > 0);
    this._renderTags();
  }

  _renderTags() {
    // リストのリセット
    this.tagListContainerTarget.innerHTML = '';
    for(let tag of this.selectedTags){
      const newTagContent = document.createElement("span");
      newTagContent.textContent = tag;
      const deleteButton = document.createElement("button");
      deleteButton.textContent = 'x';
      deleteButton.dataset.action = "click->tag-manager#removeTag";
      deleteButton.dataset.tagName = tag;
      newTagContent.appendChild(deleteButton);
      this.tagListContainerTarget.appendChild(newTagContent);
    }
    this._updateHiddenTags();
  }

  _updateHiddenTags() {
    this.hiddenInputTarget.value = this.selectedTags.join(',');
  }

  _addTagAndCleanUp(tagName) {
    this.selectedTags.includes(tagName) || this.selectedTags.push(tagName)
    this.inputTarget.value = '';
    this.searchResultTarget.innerHTML = '';
    this.searchResultTarget.style.display = 'none';
    this._renderTags();
  }

  removeTag(event) {
    const tagNameToRemove = event.target.dataset.tagName;
    this.selectedTags = this.selectedTags.filter(tag => tag !== tagNameToRemove);
    this._renderTags();
  }

  async searchTags() {
    console.log("検索開始!");
    // view側で指定したリクエスト先のURL
    const requestURL = this.data.get("searchUrl");
    // selectエレメント
    const tagElement = this.searchResultTarget;
    // イベント発火時に前のイベント時に保有していたリストを削除
    tagElement.innerHTML = '';

    // changeイベントを確実に発火するために最初にダミーの候補を入れる
    const defaultOption = document.createElement("option");
    defaultOption.value = ""; // 値は空にする
    defaultOption.textContent = "タグ候補"
    defaultOption.disabled = true; // 選択不可にする
    defaultOption.selected = true; // 最初から選択状態にする
    tagElement.appendChild(defaultOption);

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
    if (data.length > 0) {
      this.searchResultTarget.style.display = 'inline-block';
    } else {
      this.searchResultTarget.style.display = 'none';
    }
  }

  selectTag(event) {
    const selectedContent = event.target.options[event.target.selectedIndex].textContent;
    this._addTagAndCleanUp(selectedContent);
  }

  // ユーザーが候補選択しなかった場合の処理
  addTagFromInput() {
    if(this.inputTarget.value){
      this._addTagAndCleanUp(this.inputTarget.value);
    }
  }
}
