package y.phi9t.sbt

import sbt._
import Keys._
import sys.process.Process

object GenClasspathPlugin extends AutoPlugin {

  /**
    * When an auto plugin provides a stable field such as val or object named autoImport,
    * the contents of the field are wildcard imported in set, eval, and .sbt files.
    * Ref: http://www.scala-sbt.org/0.13/docs/Plugins.html
    */
  object autoImport {
    // Build a runnable script with all dependencies
    lazy val genClasspath = taskKey[Unit]("Build runnable script with classpath")
    lazy val checkArts = taskKey[Unit]("Check included artifacts")

    lazy val baseGenClasspathSettings: Seq[Def.Setting[_]] = Seq(
      checkArts := {
        val (art, file) = packagedArtifact.in(Compile, packageBin).value
        println("Artifact definition: " + art)
        println("Packaged file: " + file.getAbsolutePath)
      },

      genClasspath := {
        import java.io.PrintWriter
        // Find all jar dependencies and construct a classpath string
        val cpDir = baseDirectory.value / ".sbt.classpath"
        cpDir.mkdirs()
        val fout = new PrintWriter((cpDir / "SBT_RUNTIME_CLASSPATH").toString)

        println("Building runtime classpath for current project")
        val cp: Classpath = (fullClasspath in Runtime).value
        try fout.write(cp.files.map(_.toString).mkString(":"))
        finally fout.close()
      }
    )
  }
  import autoImport._

  override def requires = sbt.plugins.JvmPlugin

  // This plugin is automatically enabled for projects which are JvmPlugin.
  override def trigger = allRequirements

  override val projectSettings =
    inConfig(Compile)(baseGenClasspathSettings) ++ inConfig(Test)(baseGenClasspathSettings)
}
