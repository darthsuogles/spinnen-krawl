import y.phi9t.sbt.{LibDeps, LibVer}

lazy val commonSettings = Seq(
  organization := "y.phi9t",
  version := "0.1",
  scalaVersion := LibVer.scala,
  scalacOptions ++= scalafixScalacOptions.value ++ Seq(
    "-Ywarn-unused-import"
  ),
  resolvers ++= Seq(
    DefaultMavenRepository,
    Resolver.mavenLocal,
    Resolver.file("local", file(Path.userHome.absolutePath + "/.ivy2/local"))(Resolver.ivyStylePatterns)
  )
)

// Runing a task on the aggregate project will also run it on the aggregated projects.
// For details, please read multi-part projects
// http://www.scala-sbt.org/0.13/docs/Multi-Project.html
lazy val root = (project in file(".")).
  settings(commonSettings: _*).
  settings(
    name := "root",
    publishArtifact := false
  ).aggregate(
    /* Core modules */
    repl,
    agent,
    /* REPL: Apache Spark */
    sparkRepl,
    /* REPL: Google Beam */
    //scioRepl,
  )

lazy val core = (project in file("core")).
  settings(commonSettings: _*).
  settings(
    name := "core",
    publishArtifact := false
  ).aggregate(repl)

lazy val ammonite = (project in file("ammonite"))

lazy val repl = (project in file("repl")).
  settings(commonSettings: _*).
  settings(
    name := "repl",
    scalaVersion := LibVer.scala,
    libraryDependencies ++= LibDeps.ammonite
  ).aggregate(agent)

lazy val agent = (project in file("agent")).
  settings(commonSettings: _*).
  settings(
    assemblyJarName in assembly := "mem-inst.jar",
    packageOptions in (Compile, packageBin) +=
      Package.ManifestAttributes(
        "Premain-Class" -> "y.phi9t.instrument.ObjectSizeFetcher"),
    assemblyOutputPath in assembly := {
      val outFP = baseDirectory.value / ".agents" / (assemblyJarName in assembly).value
      println(outFP)
      outFP
    }
  )

// REPL: Apache Spark
lazy val sparkRepl = (project in file(".spark.repl"))
  .settings(commonSettings: _*)
  .settings(
    name := "sparkRepl",
    libraryDependencies ++= LibDeps.spark
  ).aggregate(repl).dependsOn(repl)

// // Third party tools
// lazy val scio = (project in file("scio"))
//   .settings(
//     name := "scio",
//     scalaVersion := LibVer.scala_2_12,
//     dependencyOverrides ++= Seq(
//       "io.grpc" %% "grpc-core" % "1.6.1"
//     )
//   )

// // http://www.scala-sbt.org/1.x/docs/Library-Management.html#Overriding+a+version
// lazy val scioRepl = (project in file(".scio.repl"))
//   .settings(
//     name := "scio-repl",
//     scalaVersion := LibVer.scala_2_12,
//     dependencyOverrides ++= Seq(
//       "io.grpc" %% "grpc-core" % "1.6.1"
//     )
//   ).aggregate(scio, ammonite).dependsOn(scio, ammonite)

// // TODO: check these `spPackage::artifactPath`
// lazy val spkgs = (project in file(".spark-packages")).
//   settings(
//     scalaVersion := LibVer.scala,
//     sparkVersion := LibVer.spark
//   )
//   .dependsOn(spkgAvro, spkgCoreNLP)
//   .aggregate(spkgAvro, spkgCoreNLP)

// lazy val spkgAvro = (project in file("spark-avro")).
//   settings(
//     scalaVersion := LibVer.scala,
//     sparkVersion := LibVer.spark,
//     name := "spark-avro",
//     version := "0.3.0-edge-SNAPSHOT",
//     spName := s"databricks/${name.value}"
//   )

// lazy val spkgCoreNLP = (project in file("spark-corenlp")).
//   settings(
//     scalaVersion := LibVer.scala,
//     sparkVersion := LibVer.spark,
//     sparkComponents ++= Seq(
//       "sql", "core"
//     ),
//     libraryDependencies ++= Seq(
//       "edu.stanford.nlp" % "stanford-corenlp" % "3.6.0",
//       "com.google.protobuf" % "protobuf-java" % "2.6.1"
//       //"edu.stanford.nlp" % "stanford-corenlp" % "3.6.0" % "test" classifier "models",
//       //"org.scalatest" %% "scalatest" % "2.2.6" % "test"
//     ),
//     organization := "databricks",
//     name := "spark-corenlp",
//     version := "0.3.0-edge-SNAPSHOT",
//     spName := s"databricks/${name.value}"
//   )
