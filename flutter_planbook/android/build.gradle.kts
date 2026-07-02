allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

subprojects {
    configurations.configureEach {
        resolutionStrategy {
            // home_widget 使用 glance-appwidget:1.+，会解析到需要 compileSdk 37 的 alpha 版
            force(
                "androidx.glance:glance-appwidget:1.1.1",
                "androidx.glance:glance-material3:1.1.1",
                "androidx.glance:glance:1.1.1",
            )
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
