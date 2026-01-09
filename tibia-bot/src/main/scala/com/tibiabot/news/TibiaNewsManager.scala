package com.tibiabot.news

import akka.actor.ActorSystem
import akka.http.scaladsl.Http
import akka.http.scaladsl.model.{HttpRequest, HttpResponse}
import akka.http.scaladsl.unmarshalling.Unmarshal
import com.typesafe.scalalogging.StrictLogging
import net.dv8tion.jda.api.EmbedBuilder
import net.dv8tion.jda.api.JDA
import spray.json._
import java.awt.Color
import java.io.{File, PrintWriter}
import scala.concurrent.{ExecutionContext, Future}
import scala.io.Source
import scala.util.{Failure, Success, Try}

/**
 * Model danych dla newsa z Tibia
 */
case class TibiaNewsItem(
  id: Int,
  title: String,
  url: String,
  date: String,
  `type`: String,
  category: String
)

case class TibiaNewsResponse(news: List[TibiaNewsItem])

/**
 * JSON protocol dla spray-json
 */
object TibiaNewsJsonProtocol extends DefaultJsonProtocol {
  implicit val newsItemFormat: RootJsonFormat[TibiaNewsItem] = jsonFormat6(TibiaNewsItem)
  implicit val newsResponseFormat: RootJsonFormat[TibiaNewsResponse] = jsonFormat1(TibiaNewsResponse)
}

/**
 * Manager do pobierania i wysyłania newsów z Tibia
 */
class TibiaNewsManager(implicit system: ActorSystem, ec: ExecutionContext) extends StrictLogging {
  
  import TibiaNewsJsonProtocol._
  
  private val LAST_NEWS_FILE = "last_news_id.txt"
  private val API_URL = "https://api.tibiadata.com/v4/news/latest"
  
  /**
   * Pobiera ID ostatniego sprawdzonego newsa
   */
  private def getLastNewsId(): Option[Int] = {
    Try {
      val file = new File(LAST_NEWS_FILE)
      if (file.exists()) {
        val source = Source.fromFile(file)
        val id = source.getLines().nextOption().map(_.toInt)
        source.close()
        id
      } else {
        None
      }
    }.toOption.flatten
  }
  
  /**
   * Zapisuje ID ostatniego sprawdzonego newsa
   */
  private def saveLastNewsId(newsId: Int): Unit = {
    Try {
      val writer = new PrintWriter(new File(LAST_NEWS_FILE))
      writer.write(newsId.toString)
      writer.close()
    } match {
      case Success(_) => logger.debug(s"Saved last news ID: $newsId")
      case Failure(e) => logger.error(s"Failed to save last news ID: $newsId", e)
    }
  }
  
  /**
   * Pobiera newsy z API Tibia
   */
  def fetchNews(): Future[List[TibiaNewsItem]] = {
    Http().singleRequest(HttpRequest(uri = API_URL)).flatMap {
      case HttpResponse(status, _, entity, _) if status.isSuccess() =>
        Unmarshal(entity).to[String].map { jsonString =>
          val json = jsonString.parseJson
          val newsResponse = json.convertTo[TibiaNewsResponse]
          newsResponse.news
        }
      case HttpResponse(status, _, entity, _) =>
        entity.discardBytes()
        logger.error(s"Failed to fetch Tibia news, status: $status")
        Future.successful(List.empty)
    }.recover {
      case e: Exception =>
        logger.error("Error fetching Tibia news", e)
        List.empty
    }
  }
  
  /**
   * Sprawdza nowe newsy i wysyła je na kanał
   */
def checkAndSendNews(jda: JDA, channelId: String): Future[Unit] = {
  if (channelId.isEmpty || channelId == "0") {
    logger.debug("News channel not configured, skipping news check")
    Future.successful(())
  } else {
    fetchNews().map { newsList =>
      if (newsList.isEmpty) {
        logger.debug("No news fetched from API")
      } else {
        val lastId = getLastNewsId()
        val newItems = lastId match {
          case Some(id) =>
            newsList.takeWhile(_.id != id)
          case None =>
            newsList.take(1)
        }

        if (newItems.nonEmpty) {
          Try {
            val channel = jda.getTextChannelById(channelId)
            if (channel != null && channel.canTalk()) {
              newItems.reverse.foreach { newsItem =>
                val embed = createNewsEmbed(newsItem)
                channel.sendMessageEmbeds(embed).queue()
                Thread.sleep(1000)
              }
              saveLastNewsId(newsList.head.id)
              logger.info(s"Sent ${newItems.size} new Tibia news to channel $channelId")
            } else {
              logger.warn(s"Cannot send news to channel $channelId - channel not found or no permissions")
            }
          } match {
            case Failure(e) => logger.error("Error sending news to Discord", e)
            case Success(_) => ()
          }
        } else {
          logger.debug("No new news to send")
        }
      }
    }
  }
}
  
  /**
   * Tworzy embed dla newsa
   */
  private def createNewsEmbed(newsItem: TibiaNewsItem): net.dv8tion.jda.api.entities.MessageEmbed = {
    new EmbedBuilder()
      .setTitle(newsItem.title, newsItem.url)
      .setDescription(s"Type: ${newsItem.`type`}\nDate: ${newsItem.date}")
      .addField("Category", newsItem.category, false)
      .setColor(Color.BLUE)
      .setFooter("Tibia News", "https://static.tibia.com/images/global/general/tibialogo.gif")
      .build()
  }
}
