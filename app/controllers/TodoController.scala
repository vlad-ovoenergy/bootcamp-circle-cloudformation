package controllers

import com.amazonaws.services.dynamodbv2.AmazonDynamoDB
import com.gu.scanamo.Scanamo
import play.api.mvc._
import persistence.DynamoOps

class TodoController(controllerComponents: ControllerComponents,
                     dynamoClient: AmazonDynamoDB,
                     dynamoOps: DynamoOps) extends AbstractController(controllerComponents) {

  val list = Action {
    Scanamo.exec(dynamoClient)(dynamoOps.listItems) match {
      case Left(errorMsg) => Ok(errorMsg)
      case Right(items) => Ok(views.html.list(items))
    }
  }

  val create = Action(controllerComponents.parsers.formUrlEncoded) { request =>
    request.body.get("text") match {
      case Some(Seq(text)) =>
        Scanamo.exec(dynamoClient)(dynamoOps.createItem(text))
        Redirect(routes.TodoController.list()).flashing("info" -> "Created a ToDo item")
      case _ =>
        BadRequest("Invalid form data")
    }
  }

  def remove(epochMillis: Long) = Action {
    Scanamo.exec(dynamoClient)(dynamoOps.deleteItem(epochMillis))
    Redirect(routes.TodoController.list()).flashing("info" -> "Deleted a ToDo item")
  }

}

