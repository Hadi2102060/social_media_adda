plugins {
    // Declare the Google Services plugin with version 4.4.3, applied only in subprojects
    id("com.google.gms.google-services") version "4.3.15" apply false
    // Declare the Android Gradle plugin for Android builds
    id("com.android.application") version "8.7.3" apply false
    // Declare the Kotlin Android plugin if using Kotlin in the app
    id("org.jetbrains.kotlin.android") version "2.1.0" apply false
}

buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        // Ensure Google Services plugin version 4.4.3 is used
        classpath("com.google.gms:google-services:4.4.3")
        // Android Gradle plugin
        classpath("com.android.tools.build:gradle:8.1.0")
        // Kotlin Gradle plugin
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:1.9.22")
    }
    // Force the Google Services plugin to use version 4.4.3 to avoid conflicts
    configurations.classpath {
        resolutionStrategy {
            force("com.google.gms:google-services:4.4.3")
        }
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Maintain your custom build directory logic
val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}