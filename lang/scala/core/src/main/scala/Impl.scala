package y.phi9t.core

import scala.collection.mutable

private[core] class Extnr(name: String, fn: => String) {
  def show(): String = fn
}

private[core] trait Base {
  protected val registry: mutable.ListBuffer[Extnr] = mutable.ListBuffer.empty[Extnr]
  def register(name: String)(fn: => String) = {
    registry += new Extnr(name, fn)
  }
}

private [core] trait PropA { self: Base =>
  protected val a = s"value of A: ${this.getClass.getCanonicalName}"
  self.register("prop-a") {
    s"Property A + $a"
  }
}

private [core] trait PropB { self: Base =>
  protected val b = s"value of B: ${this.getClass.getCanonicalName}"
  self.register("prop-b") {
    s"Property B + $b"
  }
}

class Impl extends Base with PropA with PropB {
  def show() = {
    println(registry.map(_.show()).mkString("\n"))
  }
}

object ImplMain extends App {
  val impl = new Impl()
  impl.show()
}
