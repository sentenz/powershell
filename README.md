# PowerShell

A task runner for automating the development workflow using PowerShell scripts and modules. PowerShell provides efficient task, dependency, and configuration management in software projects.

- [1. Usage](#1-usage)
  - [1.1. Task Runner](#11-task-runner)

## 1. Usage

### 1.1. Task Runner

- [Makefile](Makefile)
  > Refer to the Makefile as the Task Runner file.

  > [!NOTE]
  > Run the `make help` command in the terminal to list the tasks used for the project.

  ```plaintext
  $ make help

  TASK
          A collection of task runner used in the current project.

  USAGE
          make [target]

          bootstrap                Initialize a software development workspace with requisites
          setup                    Install and configure all dependencies essential for development
          teardown                 Remove development artifacts and restore the host to its pre-setup state
          install-pwsh-analyzer    Install PSScriptAnalyzer PowerShell module
          lint-pwsh-analyze        Lint PowerShell scripts and modules using PSScriptAnalyzer
  ```
