package com.example

object HelloWorld {
  def main(args: Array[String]): Unit = {
    val name = args.headOption.getOrElse("World")
    println(s"Hello, $name!")
  }
}
