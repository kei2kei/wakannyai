// Import and register all your controllers from the importmap via controllers/**/*_controller
import { application } from "controllers/application"
import { eagerLoadControllersFrom } from "@hotwired/stimulus-loading"
eagerLoadControllersFrom("controllers", application)
import TagManagerController from "./tag_manager_controller"
import NavbarController from "./navbar_controller"
import CommentController from "./comment_controller"
import MarkdownEditorController from "./markdown_editor_controller"
application.register("tag_manager", TagManagerController)
application.register("navbar", NavbarController)
application.register("comment", CommentController)
application.register("markdown", MarkdownEditorController)