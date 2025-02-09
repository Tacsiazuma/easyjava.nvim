# Easyjava.nvim

Plugin to autopopulate files based on their package and add imports in Java projects.

## Requirements

Neovim 0.9.4+

## Usage

Import it with your favourite package manager:

Lazy

```lua
{
   "tacsiazuma/easyjava.nvim",
   dependencies = { 'nvim-lua/plenary.nvim' },
   opts = {} -- so lazy calls the setup function
}
```

Whenever you open a java file or a pom.xml which is not empty it will get autopopulated.

Pom.xml template:

```xml
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>

    <groupId></groupId>
    <artifactId></artifactId>
    <version>1.0-SNAPSHOT</version>
    <packaging>jar</packaging>

    <name></name>

    <properties>
        <project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>
        <java.version>1.8</java.version>
    </properties>

    <build>
        <plugins>
            <plugin>
                <groupId>org.apache.maven.plugins</groupId>
                <artifactId>maven-compiler-plugin</artifactId>
                <version>3.1</version>
                <configuration>
                    <source>${java.version}</source>
                    <target>${java.version}</target>
                </configuration>
            </plugin>
        </plugins>
    </build>

    <dependencies>
        <dependency>
            <groupId>junit</groupId>
            <artifactId>junit</artifactId>
            <version>4.13.1</version>
            <scope>test</scope>
        </dependency>
    </dependencies>
</project>
```

## TODO

- [x] Autopopulate class and test files with boilerplate
- [ ] Add controller and repository annotations and imports.
- [ ] Configurate test frameworks to be used by default on new test classes
- [ ] Configurate java version or get it from available runtime
