package com.tibiabot.scheduler

import akka.actor.ActorSystem
import com.tibiabot.rashid.RashidData
import com.tibiabot.news.TibiaNewsManager
import com.typesafe.scalalogging.StrictLogging
import net.dv8tion.jda.api.{EmbedBuilder, JDA}
import scala.concurrent.ExecutionContext
import scala.concurrent.duration._
import java.awt.Color
import java.time.{LocalDateTime, LocalTime, ZoneId, ZonedDateTime}
import java.util.concurrent.TimeUnit

/**
 * Manager dla zaplanowanych zadań (daily Rashid, news check)
 */
class ScheduledTasksManager(
  jda: JDA,
  rashidChannelId: String,
  newsChannelId: String
)(implicit system: ActorSystem, ec: ExecutionContext) extends StrictLogging {
  
  private val newsManager = new TibiaNewsManager()
  
  /**
   * Uruchamia wszystkie zaplanowane zadania
   */
  def start(): Unit = {
    scheduleDailyRashidMessage()
    scheduleNewsCheck()
    logger.info("Scheduled tasks started")
  }
  
  /**
   * Planuje codzienną wiadomość o Rashidzie o 11:00
   */
  private def scheduleDailyRashidMessage(): Unit = {
    if (rashidChannelId.isEmpty || rashidChannelId == "0") {
      logger.info("Rashid channel not configured, skipping daily Rashid messages")
      return
    }
    
    val targetTime = LocalTime.of(11, 0) // 11:00
    val initialDelay = calculateInitialDelay(targetTime)
    
    system.scheduler.scheduleAtFixedRate(
      initialDelay = initialDelay,
      interval = 24.hours
    ) { () =>
      sendDailyRashidMessage()
    }
    
    logger.info(s"Daily Rashid message scheduled at 11:00 (initial delay: ${initialDelay.toMinutes} minutes)")
  }
  
  /**
   * Planuje sprawdzanie newsów co godzinę
   */
  private def scheduleNewsCheck(): Unit = {
    if (newsChannelId.isEmpty || newsChannelId == "0") {
      logger.info("News channel not configured, skipping news checks")
      return
    }
    
    // Pierwsze sprawdzenie po 1 minucie, potem co godzinę
    system.scheduler.scheduleAtFixedRate(
      initialDelay = 1.minute,
      interval = 1.hour
    ) { () =>
      newsManager.checkAndSendNews(jda, newsChannelId)
    }
    
    logger.info("News check scheduled every hour")
  }
  
  /**
   * Wysyła codzienną wiadomość o Rashidzie
   */
  private def sendDailyRashidMessage(): Unit = {
    try {
      val channel = jda.getTextChannelById(rashidChannelId)
      
      if (channel != null && channel.canTalk()) {
        RashidData.getTodayLocation() match {
          case Some(location) =>
            val embed = createRashidEmbed(location)
            channel.sendMessageEmbeds(embed).queue()
            logger.info(s"Daily Rashid message sent to channel $rashidChannelId")
            
          case None =>
            logger.error("Unable to determine Rashid's location for daily message")
        }
      } else {
        logger.warn(s"Cannot send daily Rashid message to channel $rashidChannelId - channel not found or no permissions")
      }
    } catch {
      case e: Exception =>
        logger.error("Error sending daily Rashid message", e)
    }
  }
  
  /**
   * Tworzy embed z informacjami o Rashidzie
   */
  private def createRashidEmbed(location: com.tibiabot.rashid.RashidLocation): net.dv8tion.jda.api.entities.MessageEmbed = {
    new EmbedBuilder()
      .setTitle("Informations:")
      .setColor(new Color(0, 255, 0)) // Zielony
      .addField(
        "",
        s"[Rashid](https://tibiopedia.pl/npcs/Rashid)\n\n${location.description}",
        true
      )
      .setThumbnail(location.imageUrl)
      .setImage(location.mapImageUrl)
      .build()
  }
  
  /**
   * Oblicza opóźnienie do następnego wystąpienia podanej godziny
   */
  private def calculateInitialDelay(targetTime: LocalTime): FiniteDuration = {
    val now = ZonedDateTime.now(ZoneId.systemDefault())
    val nowTime = now.toLocalTime
    
    val targetToday = now.toLocalDate.atTime(targetTime).atZone(ZoneId.systemDefault())
    
    val targetDateTime = if (nowTime.isAfter(targetTime)) {
      // Jeśli już minęła godzina dzisiaj, zaplanuj na jutro
      targetToday.plusDays(1)
    } else {
      targetToday
    }
    
    val delayMillis = targetDateTime.toInstant.toEpochMilli - now.toInstant.toEpochMilli
    FiniteDuration(delayMillis, TimeUnit.MILLISECONDS)
  }
}
