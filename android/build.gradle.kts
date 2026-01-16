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

// Fix for packages missing namespace (AGP 8.0+)
subprojects {
    val configureNamespace = {
        val android = project.extensions.findByName("android")
        if (android != null) {
            // Use reflection or dynamic access to avoid classpath issues
             val namespaceProp = android.javaClass.getMethod("getNamespace")
             val setNamespaceMethod = android.javaClass.getMethod("setNamespace", String::class.java)
             
             if (namespaceProp.invoke(android) == null) {
                 val newNamespace = "com.adhann.${project.name.replace("-", "_")}"
                 setNamespaceMethod.invoke(android, newNamespace)
             }
        }
    }

    if (project.state.executed) {
        configureNamespace()
    } else {
        project.afterEvaluate {
            configureNamespace()
        }
    }
}
