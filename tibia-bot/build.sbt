val akkaVersion     = "2.8.5"
val akkaHttpVersion = "10.5.3"

name := "optimum-bot"
version := "1.0.0"

ThisBuild / scalaVersion := "2.13.12"

lazy val root = (project in file("."))
  .settings(
    libraryDependencies ++= Seq(
      "com.typesafe" % "config" % "1.4.2",

      "com.typesafe.akka" %% "akka-actor-typed" % akkaVersion,
      "com.typesafe.akka" %% "akka-stream"      % akkaVersion,
      "com.typesafe.akka" %% "akka-http"        % akkaHttpVersion,
      "com.typesafe.akka" %% "akka-http-spray-json" % akkaHttpVersion,

      "com.typesafe.scala-logging" %% "scala-logging" % "3.9.5",
      "ch.qos.logback" % "logback-classic" % "1.2.10",
      "org.codehaus.janino" % "janino" % "3.1.6",
      "com.github.napstr" % "logback-discord-appender" % "1.0.0",

      "net.dv8tion" % "JDA" % "5.0.0-beta.4",
      "club.minnced" % "discord-webhooks" % "0.8.2",

      "org.apache.commons" % "commons-text" % "1.10.0",
      "org.postgresql" % "postgresql" % "42.5.4",
      "com.google.guava" % "guava" % "30.1.1-jre",

      "org.scalactic" %% "scalactic" % "3.2.15",
      "org.scalatest" %% "scalatest" % "3.2.15" % Test,
      "org.scalamock" %% "scalamock" % "5.2.0" % Test
    ),

    resolvers += "jitpack" at "https://jitpack.io"
  )

assembly / mainClass := Some("com.tibiabot.BotApp")

assembly / assemblyMergeStrategy := {
  case PathList("reference.conf")    => MergeStrategy.concat
  case PathList("application.conf")  => MergeStrategy.concat
  case PathList("META-INF", _ @ _*)  => MergeStrategy.discard
  case x =>
    val old = (assembly / assemblyMergeStrategy).value
    old(x)
}
