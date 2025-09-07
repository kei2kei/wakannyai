# frozen_string_literal: true
module FormHelpers
  def set_easy_mde(text, container: ".EasyMDEContainer .CodeMirror")
    expect(page).to have_css(container)
    cm = find(container, visible: :all)
    page.execute_script(
      "arguments[0].CodeMirror.setValue(arguments[1]); arguments[0].CodeMirror.save();",
      cm.native, text
    )
  end

  def tagify_add(input_selector, *tags)
    page.execute_script(<<~JS, input_selector, tags)
      (function(selector, tags){
        var el = document.querySelector(selector);
        if (el && el.tagify) { el.tagify.addTags(tags); }
      })(arguments[0], arguments[1]);
    JS
  end
end

RSpec.configure { |c| c.include FormHelpers, type: :system }
