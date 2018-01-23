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
      case Right(items) => Ok(s"TODO template. $items")
    }

  }

}
