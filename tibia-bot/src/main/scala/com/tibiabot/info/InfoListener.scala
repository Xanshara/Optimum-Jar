package com.tibiabot.info

import net.dv8tion.jda.api.EmbedBuilder
import net.dv8tion.jda.api.events.interaction.command.SlashCommandInteractionEvent
import net.dv8tion.jda.api.hooks.ListenerAdapter
import com.typesafe.scalalogging.StrictLogging
import java.awt.Color
import java.time.LocalDateTime
import java.time.format.DateTimeFormatter

/**
 * Listener dla komendy /info
 */
class InfoListener extends ListenerAdapter with StrictLogging {
  
  // Data uruchomienia bota (statyczna)
  private val startTime = LocalDateTime.now()
  
  override def onSlashCommandInteraction(event: SlashCommandInteractionEvent): Unit = {
    if (event.getName == "info") {
      handleInfo(event)
    }
  }
  
  /**
   * Obsługa komendy /info
   */
  private def handleInfo(event: SlashCommandInteractionEvent): Unit = {
    event.deferReply().queue()
    
    try {
      val embed = createInfoEmbed()
      event.getHook.sendMessageEmbeds(embed).queue()
    } catch {
      case e: Exception =>
        logger.error("Error in /info command", e)
        val errorEmbed = new EmbedBuilder()
          .setDescription("❌ An error occurred while fetching bot information.")
          .setColor(Color.RED)
          .build()
        event.getHook.sendMessageEmbeds(errorEmbed).queue()
    }
  }
  
  /**
   * Tworzy embed z informacjami o bocie
   */
  private def createInfoEmbed(): net.dv8tion.jda.api.entities.MessageEmbed = {
    val formatter = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss")
    val formattedStartTime = startTime.format(formatter)
    
    val embed = new EmbedBuilder()
      .setTitle("Informacje o bocie")
      .setColor(new Color(255, 102, 0)) // Pomarańczowy (#FF6600)
      .addField(
        "Właściciel bota",
        "👑 Właściciel: Sinrac\n\nPrawa do bota i jego kodu są zastrzeżone.",
        false
      )
      .addField(
        "Zastrzeżenia prawne",
        "📝 Wszystkie prawa zastrzeżone. Żadna część tego bota nie może być używana lub " +
        "reprodukowana bez zgody właściciela.",
        false
      )
      .addField(
        "Wersja bota",
        "🛠️ Wersja: v1.9.0",
        false
      )
      .addField(
        "Data uruchomienia",
        s"📅 Data uruchomienia: $formattedStartTime",
        false
      )
      .addField(
        "Informacje dodatkowe",
        "🤖 Optimum Bot to zaawansowany bot do śledzenia aktywności w grze Tibia MMORPG.",
        false
      )
      .addField(
        "Dostępne komendy",
        "📝 **/setup** - Konfiguracja bota dla świata Tibia\n\n" +
        "📝 **/hunted** - Zarządzanie listą wrogów\n\n" +
        "📝 **/allies** - Zarządzanie listą sojuszników\n\n" +
        "📝 **/neutral** - Zarządzanie listą neutralnych\n\n" +
        "📝 **/online** - Konfiguracja kanałów online\n\n" +
        "📝 **/split_loot** - Dzieli łup z party huntu\n\n" +
        "📝 **/rashid** - Wyświetla lokalizację Rashida\n\n" +
        "📝 **/info** - Informacje o bocie\n\n" +
        "📜 Więcej komend dostępnych po wpisaniu `/` na serwerze.",
        false
      )
      .build()
    
    embed
  }
}
