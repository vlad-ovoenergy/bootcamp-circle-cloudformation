package controllers

import play.api.mvc.{AbstractController, ControllerComponents}

class MainController(controllerComponents: ControllerComponents) extends AbstractController(controllerComponents) {

  val index = Action(Ok("hello world"))

}
