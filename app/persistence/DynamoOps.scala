package persistence

import cats.free.Free
import com.gu.scanamo._
import com.gu.scanamo.syntax._
import com.gu.scanamo.ops.{ScanamoOps, ScanamoOpsA}
import models.TodoItem

import scala.language.postfixOps

class DynamoOps(table: Table[TodoItem]) {

  private val HashValue = "ToDo"

  /**
    * Retrieve all ToDo items, sorted by creation time (newest first)
    */
  def listItems: ScanamoOps[Either[String, List[TodoItem]]] = {
    if (table.name == "dunno")
      Free.pure(Left("Oops, you don't have a DynamoDB table yet :("))
    else {
      for {
        items <- table.query('hash -> HashValue descending)
      } yield Right(items.flatMap(_.toOption))
    }
  }

  /**
    * Create a new ToDo item with the given content
    */
  def createItem(text: String): ScanamoOps[TodoItem] =
    for {
      item <- Free.pure[ScanamoOpsA, TodoItem](TodoItem(HashValue, System.currentTimeMillis(), text))
      _ <- table.put(item)
    } yield item

  /**
    * Delete the ToDo item created at the given time.
    * Does nothing if the item does not exist.
    */
  def deleteItem(epochMillis: Long): ScanamoOps[Unit] =
    for {
      _ <- table.delete('hash -> HashValue and ('epochMillis -> epochMillis))
    } yield ()

}
