# Easyjava.nvim

Plugin to autopopulate files based on their package and add imports in Java projects.

## Usage

Import it with your favourite package manager:

Lazy

```
{
   "tacsiazuma/easyjava.nvim",
   dependencies = { 'nvim-lua/plenary.nvim' },
   opts = {} -- so lazy calls the setup function
}
```

Whenever you open a java file or a pom.xml which is not empty it will get autopopulated.

## TODO

- [x] Autopopulate class and test files with boilerplate
- [ ] Add controller and repository annotations and imports.
- [ ] Configurate test frameworks to be used by default on new test classes
