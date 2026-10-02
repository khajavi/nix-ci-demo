package com.example

class HelloWorldTest extends munit.FunSuite {
  test("greeting contains expected text") {
    val greeting = "Hello, World!"
    assert(greeting.startsWith("Hello"))
  }
}
