import com.amazonaws.services.dynamodbv2.AmazonDynamoDBClient
import com.gu.scanamo._
import controllers.TodoController
import models.TodoItem
import persistence.DynamoOps
import play.api.mvc.EssentialFilter
import play.api.routing.Router
import play.api.{Application, ApplicationLoader, BuiltInComponentsFromContext}
import router.Routes

class AppComponents(context: ApplicationLoader.Context) extends BuiltInComponentsFromContext(context) {
  val dynamoClient = AmazonDynamoDBClient.builder().build()
  val tableName = configuration.get[String]("dynamo.table")
  val dynamoTable: Table[TodoItem] = Table[TodoItem](tableName)

  val todoController = new TodoController(controllerComponents, dynamoClient, new DynamoOps(dynamoTable))

  override def router: Router = new Routes(httpErrorHandler, todoController)
  override def httpFilters: Seq[EssentialFilter] = Nil
}

class AppLoader extends ApplicationLoader {
  override def load(context: ApplicationLoader.Context): Application = new AppComponents(context).application
}
