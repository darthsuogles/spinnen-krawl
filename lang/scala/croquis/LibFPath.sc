import java.nio.file.{Path, Paths, Files}

case class FPath(fp: Path) {
  def /(fpath: FPath): FPath = new FPath(fp.resolve(fpath.fp))
}
object FPath {
  object Implicits {
    implicit def str2fpath(s: String): FPath = new FPath(Paths.get(s))
  }
  lazy val home = new FPath(Paths.get(System.getProperty("user.home")))
}
