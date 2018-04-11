package y.phi9t.sbt

import sbt._

object LibVer {
  lazy val scala = scala_2_11
  lazy val scala_2_11 = "2.11.12"
  lazy val scala_2_12 = "2.12.4"

  lazy val ammonite = "1.1.0"
  lazy val ammonite_2_11 = "1.1.0-3-73d5734"
  lazy val ammonite_2_12 = "1.1.0-3-73d5734"

  lazy val scalameta = "3.6.0"
  lazy val scalameta_2_12 = "3.6.0"
  // Spark
  lazy val spark = "2.3.0"
  lazy val sparkMaster = "2.4.0-SNAPSHOT"
  // Akka: https://github.com/akka/akka/releases
  lazy val akka = "2.5.9"
  // BEAM via Scio
}

object LibDeps {

  //resolvers += "Typesafe Releases" at "http://repo.typesafe.com/typesafe/releases/"
  lazy val akka = Seq(
    "akka-actor",
    "akka-agent",
    "akka-cluster",
    "akka-cluster-metrics",
    "akka-cluster-sharding",
    "akka-cluster-tools",
    "akka-stream",
    "akka-slf4j",
    "akka-testkit"
  ) map { "com.typesafe.akka" %% _ % LibVer.akka }

  private lazy val sparkModules = Seq(
    "spark-core",
    "spark-sql",
    "spark-streaming",
    "spark-mllib",
    "spark-graphx"
  )
  lazy val sparkMaster = sparkModules.map {
    "org.apache.spark" %% _ % LibVer.sparkMaster }
  lazy val spark = sparkModules.map {
    "org.apache.spark" %% _ % LibVer.spark }

  lazy val ammonite = Seq(
    "com.lihaoyi" % s"ammonite_${LibVer.scala}" % LibVer.ammonite,
    "org.scalameta" %% "scalameta" % LibVer.scalameta
  )

  lazy val ammonite_2_12 = Seq(
    "com.lihaoyi" % s"ammonite_${LibVer.scala_2_12}" % LibVer.ammonite_2_12,
    "org.scalameta" %% "scalameta" % LibVer.scalameta_2_12
  )
}
