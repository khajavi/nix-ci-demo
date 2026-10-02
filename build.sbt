ThisBuild / name := "hello-world-scala"
ThisBuild / version := "0.1.0"
val scala213 = "2.13.18"
val scala3 = "3.3.8"

ThisBuild / scalaVersion := scala3
ThisBuild / crossScalaVersions := Seq(scala213, scala3)
ThisBuild / organization := "com.example"

lazy val root = (project in file("."))
  .settings(
    libraryDependencies ++= Seq(
      "org.scalameta" %% "munit" % "0.7.29" % Test
    ),
    scalacOptions ++= Seq(
      "-deprecation",
      "-feature",
      "-unchecked",
      "-Xfatal-warnings"
    ),
    javacOptions ++= Seq(
      "-source",
      "21",
      "-target",
      "21"
    )
  )
