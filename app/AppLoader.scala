import controllers.MainController
import play.api.mvc.EssentialFilter
import play.api.routing.Router
import play.api.{Application, ApplicationLoader, BuiltInComponentsFromContext}
import router.Routes

class AppComponents(context: ApplicationLoader.Context) extends BuiltInComponentsFromContext(context) {
  val mainController = new MainController(controllerComponents)

  override def router: Router = new Routes(httpErrorHandler, mainController)
  override def httpFilters: Seq[EssentialFilter] = Nil
}
class AppLoader extends ApplicationLoader {
  override def load(context: ApplicationLoader.Context): Application = new AppComponents(context).application
}
