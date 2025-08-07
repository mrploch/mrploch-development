# Repository Configuration

## Root Folder

The [root-folder](./root-folder) contains common files that should be used as a template in a new repository.
Files should be adjusted to the project. Two types of the items should be changed (or set using environment variables):

- items that reference properties `$(MRPLOCH_ORG_*)`
- items with value `_CHANGE_ME__`

Items referencing properties should either 

It contains:

- [`.editorconfig`](./root-folder/.editorconfig)
- [`Directory.Build.props`](./root-folder/Directory.Build.props)
  - .NET version
  - Language version
  - Analysis level
  - Enabling implicit usings and nullables
  - etc.
- [`Directory.Packages.props`]
  - Centralized package versions
  - Enabling analyzer packages

## Developer Activities

### Creating New Solutions

### Creating New Projects

#### Checklist

- [ ] Create a corresponding test project
- [ ] Edit the `csproj` files for both projects and remove all properties already listed in the `Directory.Build.props` file



