// Import and register all your controllers from the importmap via controllers/**/*_controller
import { application } from "controllers/application"
import { eagerLoadControllersFrom } from "@hotwired/stimulus-loading"
eagerLoadControllersFrom("controllers", application)
import TagManagerController from "./tag_manager_controller"
import NavbarController from "./navbar_controller"
application.register("tag_manager", TagManagerController)
application.register("navbar", NavbarController)