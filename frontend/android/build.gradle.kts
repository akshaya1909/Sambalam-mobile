allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

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

subprojects {
    project.configurations.all {
        resolutionStrategy.eachDependency {
            // Force older stable version of browser
            if (requested.group == "androidx.browser" && requested.name == "browser") {
                useVersion("1.8.0")
            }
            // Force older stable version of core libraries
            if (requested.group == "androidx.core" && (requested.name == "core" || requested.name == "core-ktx")) {
                useVersion("1.15.0")
            }
        }
    }
}