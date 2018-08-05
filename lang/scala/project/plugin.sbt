
resolvers ++= Seq(
  Resolver.url(
    "artifactory", url("http://scalasbt.artifactoryonline.com/scalasbt/sbt-plugin-releases")
  )(Resolver.ivyStylePatterns),
  "Typesafe Repository" at "http://repo.typesafe.com/typesafe/releases/",
  "sonatype-releases" at "https://oss.sonatype.org/content/repositories/releases/",
  "bintray-spark-packages" at "https://dl.bintray.com/spark-packages/maven/"
)

addSbtPlugin("com.eed3si9n" % "sbt-assembly" % "latest.integration")
addSbtPlugin("com.jsuereth" % "sbt-pgp" % "latest.integration")
addSbtPlugin("org.scoverage" % "sbt-scoverage" % "latest.integration")
addSbtPlugin("org.scalastyle" %% "scalastyle-sbt-plugin" % "latest.integration")
addSbtPlugin("com.github.gseitz" % "sbt-release" % "latest.integration")
addSbtPlugin("ch.epfl.scala" % "sbt-scalafix" % "latest.integration")

// addSbtPlugin("org.spark-packages" % "sbt-spark-package" % "0.2.6")
// addSbtPlugin("org.foundweekends" % "sbt-bintray" % "0.5.1")

// From Scio
addSbtPlugin("com.cavorite" % "sbt-avro-1-8" % "1.1.3")
//addSbtPlugin("com.eed3si9n" % "sbt-assembly" % "0.14.6")
addSbtPlugin("com.eed3si9n" % "sbt-unidoc" % "0.4.1")
addSbtPlugin("com.github.gseitz" % "sbt-protobuf" % "0.6.3")
//addSbtPlugin("com.github.gseitz" % "sbt-release" % "1.0.7")
//addSbtPlugin("com.jsuereth" % "sbt-pgp" % "1.1.0")
addSbtPlugin("com.typesafe.sbt" % "sbt-ghpages" % "0.6.2")
//addSbtPlugin("org.scalastyle" % "scalastyle-sbt-plugin" % "1.0.0")
//addSbtPlugin("org.scoverage" % "sbt-scoverage" % "1.5.1")
addSbtPlugin("org.xerial.sbt" % "sbt-sonatype" % "2.0")
addSbtPlugin("pl.project13.scala" % "sbt-jmh" % "0.2.27")

libraryDependencies ++= Seq(
  "com.github.os72" % "protoc-jar" % "3.3.0.1"
)

// From Ammonite
addSbtPlugin("com.lihaoyi" % "scalatex-sbt-plugin" % "latest.release")
addSbtPlugin("com.thoughtworks.sbt-api-mappings" % "sbt-api-mappings" % "latest.release")
addSbtPlugin("io.get-coursier" % "sbt-coursier" % "latest.release")
