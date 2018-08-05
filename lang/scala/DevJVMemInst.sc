// -*- scala -*-

import y.phi9t.instrument.ObjectSizeFetcher
import scala.reflect.runtime.{universe => ru}
import scala.reflect.runtime.universe._

ObjectSizeFetcher.getObjectSize(new String("abcd"))

class A; class B extends A
assert((typeOf[B] <:< typeOf[A]) && !(typeOf[A] <:< typeOf[B]))

// https://medium.com/@sinisalouc/overcoming-type-erasure-in-scala-8f2422070d20
def compareType[T: TypeTag, U: TypeTag](v1: T, v2: U) = typeOf[U] =:= typeOf[T]
val s = List("string"); s.isInstanceOf[List[Int]]
val s = Seq("string"); s.isInstanceOf[List[Int]]
val s = Array("string"); s.isInstanceOf[Array[Int]]
compareType(Seq(1,2), Seq(2))

final class Zut(private val w: Int) {
  override def toString = s"w = $w"
}

def zutField(f: String) = ru.typeOf[Zut].declaration(ru.TermName(f)).asTerm
def zutMethod(f: String) = ru.typeOf[Zut].declaration(ru.TermName(f)).asMethod

val obj = new Zut(2)
val m = ru.runtimeMirror(obj.getClass.getClassLoader)

val im = m.reflect(obj)
im.reflectField(zutField("w")).get.asInstanceOf[Int]
val mtd = im.reflectMethod(zutMethod("toString"))
mtd.apply().asInstanceOf[String]
