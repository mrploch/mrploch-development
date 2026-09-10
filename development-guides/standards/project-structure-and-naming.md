# MrPloch Project Structure and Naming

## Overview

This document contains information on how to structure a `.NET` project in the GitHub MrPloch organization.

It defines common project types and specifies where they should be placed, and how they should be named.

It is the canonical reference used to generate:

- **`dotnet new` templates** — scaffolding a new project/layer inside an existing repo.
- **GitHub repository templates** — scaffolding a brand-new repository with the correct top-level shape.
- **Sample applications** — end-to-end reference apps that exercise every rule in this document, so a template can be validated against a real, buildable example rather than an abstract description.

Two worked examples anchor every rule below:

| Example | Repository shape | Application type |
|---|---|---|
| **`ploch-crawler`** | Single-project repository (the whole repo is one product) | Console App with Data Access |
| **`ploch-ai-tools` → `ConfigTracker`** | Multi-project repository (several unrelated deliverables share one repo) | Console App with Data Access (data/domain layers only, as of this writing — no UI host yet) |

Both are real, currently-building code — not illustrative pseudocode. Where an example's code diverges from the ideal (a missing layer, an unused reference), this document says so rather than silently correcting it, because templates must be generated from what is actually true today.

---

## 1. Repository Shapes

Every MrPloch repository is one of two shapes. Which shape a repo is decides where the `{Area}` segment (see [§2](#2-the-naming-pattern)) goes and whether it exists at all.

### 1.1 Single-Project Repository (the default)

**One repository delivers one product.** `src/` and `tests/` sit at the repository root, and every project under them belongs to that one product. This is the shape every new repository should use unless there is a specific reason to host multiple products together.

```text
ploch-crawler/                              <- repo root = the product
├── Ploch.Crawler.slnx
├── Directory.Build.props
├── Directory.Packages.props
├── src/
│   ├── Model/            Ploch.Crawler.Model.csproj
│   ├── Data/             Ploch.Crawler.Data.csproj
│   ├── Data.PostgreSql/  Ploch.Crawler.Data.PostgreSql.csproj
│   ├── UseCases/         Ploch.Crawler.UseCases.csproj
│   └── UI.ConsoleApp/    Ploch.Crawler.UI.ConsoleApp.csproj
└── tests/
    ├── UseCases.Tests/                    Ploch.Crawler.UseCases.Tests.csproj
    └── Data.PostgreSql.IntegrationTests/  Ploch.Crawler.Data.PostgreSql.IntegrationTests.csproj
```

Naming pattern: `Ploch.{Product}.{Layer}[.{Qualifier}]` — no `{Area}` segment. `ploch-crawler` is the live example; every project name in it maps directly onto a row in the [Canonical Layers](#3-canonical-layers) table.

### 1.2 Multi-Project Repository

**One repository hosts several unrelated deliverables.** This is a deliberate exception, used when the deliverables are small, related by tooling rather than by domain, or benefit from shared CI/analyser configuration more than they would from separation. `ploch-ai-tools` is the live example: it hosts MCP servers, API clients, the `KnowledgeBase` app, and the `ConfigTracker` app side by side.

```text
ploch-ai-tools/                             <- repo root = a family of deliverables
├── Ploch.AI.slnx                           <- lists everything
├── Ploch.AI.ConfigTracker.slnx             <- scoped solution: only this deliverable + its deps
├── src/
│   ├── ConfigTracker/                      <- {Area} becomes a directory LEVEL
│   │   ├── Model/       Ploch.AI.ConfigTracker.Model.csproj
│   │   ├── Data/        Ploch.AI.ConfigTracker.Data.csproj
│   │   ├── Data.SQLite/     Ploch.AI.ConfigTracker.Data.SQLite.csproj
│   │   ├── Data.SqlServer/  Ploch.AI.ConfigTracker.Data.SqlServer.csproj
│   │   └── Shared/          ServiceCollectionRegistrations.cs (linked file, not its own project — see §5.3)
│   ├── KnowledgeBase/                      <- a second, unrelated deliverable, same pattern
│   ├── McpServers/
│   ├── Clients/
│   └── ConsoleApp/
└── tests/
    ├── ConfigTracker/
    │   ├── Model.Tests/                Ploch.AI.ConfigTracker.Model.Tests.csproj
    │   └── Data.IntegrationTests/      Ploch.AI.ConfigTracker.Data.IntegrationTests.csproj
    ├── KnowledgeBase/
    └── ...
```

Naming pattern: `Ploch.{Product}.{Area}.{Layer}[.{Qualifier}]` — `{Product}` is the repository's shared brand (`AI`), `{Area}` is the individual deliverable (`ConfigTracker`). The `{Area}` segment becomes a **directory level**, not part of the leaf directory name: the directory is `src/ConfigTracker/Model/`, never `src/ConfigTracker.Model/`.

**A scoped solution file per deliverable is good practice in this shape.** `Ploch.AI.ConfigTracker.slnx` lists only the ConfigTracker projects (plus the repo-root config files), so CI and local builds for that deliverable are not coupled to, or broken by, the other deliverables in the repo. The full `Ploch.AI.slnx` still lists everything, for whole-repo operations.

### 1.3 Mapping between the two shapes

This is the concrete answer to "what would ConfigTracker look like with its own repository": strip the `{Area}` directory level and the `{Area}` name segment, everything else is unchanged.

| Multi-project repo (`ploch-ai-tools`, as it exists today) | Same project, in a hypothetical standalone `ploch-configtracker` repo |
|---|---|
| `src/ConfigTracker/Model/Ploch.AI.ConfigTracker.Model.csproj` | `src/Model/Ploch.ConfigTracker.Model.csproj` |
| `src/ConfigTracker/Data/Ploch.AI.ConfigTracker.Data.csproj` | `src/Data/Ploch.ConfigTracker.Data.csproj` |
| `src/ConfigTracker/Data.SQLite/Ploch.AI.ConfigTracker.Data.SQLite.csproj` | `src/Data.SQLite/Ploch.ConfigTracker.Data.SQLite.csproj` |
| `tests/ConfigTracker/Model.Tests/Ploch.AI.ConfigTracker.Model.Tests.csproj` | `tests/Model.Tests/Ploch.ConfigTracker.Model.Tests.csproj` |

Everything else — the layer names, the four-names-one-string rule, the casing rules — is identical in both shapes. **Never decide the layer set differently based on repository shape**; only the presence and position of `{Area}` changes.

---

## 2. The Naming Pattern

```text
Ploch.{Product}[.{Area}].{Layer}[.{Qualifier}]...
```

`{Qualifier}` may repeat — the trailing `...` above is the grammar's way of saying so. `Ploch.Crawler.Data.PostgreSql.IntegrationTests` chains two qualifiers (provider, then test kind).

| Segment | Required | Meaning | Examples |
|---|---|---|---|
| `Ploch` | Always | Organisation prefix. Every project, including tests and samples. | — |
| `{Product}` | Always | The product or library family the repo delivers. | `Crawler`, `AI`, `Common`, `Data` |
| `{Area}` | Only in a multi-project repository ([§1.2](#12-multi-project-repository)) | A distinct deliverable inside a repo that hosts several. | `ConfigTracker`, `KnowledgeBase` |
| `{Layer}` | Always **in an application repo**; optional in a shared-library repo (see note) | The architectural layer. Must come from the closed set in [§3](#3-canonical-layers). | `Domain`, `Data`, `UseCases`, `UI` |
| `{Qualifier}` | Optional, **repeatable** | Narrows the layer: a provider, technology, slice, or test kind. More than one may appear, applied left to right. | `PostgreSql`, `SQLite`, `ConsoleApp`; chained in `Ploch.Crawler.Data.PostgreSql.IntegrationTests` (provider + test kind) |

**Shared-library repos are the exception to a mandatory `{Layer}`.** This standard governs *application* repos. A library family names its projects by **feature area**, not architectural layer, and its root package legitimately has no segment after `{Product}` at all:

| Project | Shape |
|---|---|
| `Ploch.Common` | `Ploch.{Product}` — the root package of a library family; no layer segment |
| `Ploch.Common.Serialization` | `Ploch.{Product}.{FeatureArea}` |
| `Ploch.Data.EFCore.SqLite` | `Ploch.{Product}.{FeatureArea}.{Qualifier}` |
| `Ploch.TestingSupport` | `Ploch.{Product}` — another root shared-library package, same shape as `Ploch.Common` |

`Ploch.Data.Model` (the marker-interface package consumed by every app's `.Domain` project, see [§3.1](#31-domain)) is the same shape: `Ploch.{Product}.{FeatureArea}`, not a `.Domain` layer of its own — it is a library, not an application.

Do not force a library into `.Domain`/`.UseCases`/`.UI`; a shared library has no application layers of its own. The closed layer set in [§3](#3-canonical-layers) applies to application repos, and [§3.3](#33-application) says the same thing from the other direction.

### 2.1 Four Names, One String

The project file name is the single source of truth. In an SDK-style project these all derive from it by default:

| Name | Derived from | Result |
|---|---|---|
| Project file | — | `Ploch.Crawler.Data.PostgreSql.csproj` |
| `AssemblyName` | project file name | `Ploch.Crawler.Data.PostgreSql.dll` |
| `RootNamespace` | project file name | `namespace Ploch.Crawler.Data.PostgreSql;` |
| `PackageId` | `AssemblyName` | `Ploch.Crawler.Data.PostgreSql` |

**Never set `AssemblyName`, `RootNamespace`, or `PackageId` by hand.** Overriding any one of them breaks the chain and lets the four names drift apart. Neither `ploch-crawler` nor `ConfigTracker` overrides any of the three anywhere in this workspace — get the project **file name** right and the rest follows for free.

The **directory** is the only name that differs: it is the project name with the `Ploch.{Product}[.{Area}].` prefix stripped, which is exactly the directory layout shown in [§1](#1-repository-shapes) above.

### 2.2 Alignment with the .NET Framework Design Guidelines

This is a workspace-specific application of Microsoft's own guidance, not a local invention. The [namespace naming guidelines](https://learn.microsoft.com/dotnet/standard/design-guidelines/names-of-namespaces) specify:

```text
<Company>.(<Product>|<Technology>)[.<Feature>][.<Subnamespace>]
```

which maps segment-for-segment onto the pattern above — `Ploch` is `<Company>`, `{Product}` is `<Product>`, `{Layer}` is `<Feature>`, `{Qualifier}` is `<Subnamespace>`. The [assembly guidelines](https://learn.microsoft.com/dotnet/standard/design-guidelines/names-of-assemblies-and-dlls) then recommend naming the DLL after "the common prefix of the namespaces contained in the assembly" — the one-project-one-namespace-root rule in [§2.1](#21-four-names-one-string).

Two further points from those guidelines are load-bearing here:

- **"DO use a stable, version-independent product name at the second level."** `{Product}` names the product, never a version, a team, or a delivery phase.
- **"DO NOT use organizational hierarchies as the basis for names."** This is why the presentation and service groups ([§3.4](#34-presentation--the-ui-group), [§3.5](#35-services--the-api-group)) are technology groups, not org-chart splits.

**On plural namespace names:** the guidelines say "CONSIDER using plural namespace names where appropriate" (`System.Collections`). Layer segments here are singular — `.Domain`, `.Data`, `.UseCases` names an architectural layer, not a collection of instances. This is why the domain project is `.Domain` and never `.Models` or `.Entities`.

---

## 3. Canonical Layers

This is a closed set — **except [§3.5](#35-services--the-api-group), `.Api.*`, which is marked provisional below and is not yet part of the validated closed set.** A project whose layer segment is not in this table (nor `.Api.*`) needs a justification recorded in the repository's README before it is created.

### 3.1 Domain

| Layer | Project | Contains |
|---|---|---|
| `.Domain` | `Ploch.{Product}[.{Area}].Domain` | Entity POCOs, value objects, enums — and, when the app grows them, domain services, domain events and invariant-enforcing behaviour. **One project, always.** |

**There is exactly one domain project, and it is called `.Domain`.** Do not split entities into one project and behaviour into another; do not name it `.Model`, `.Models`, `.DomainModel`, `.Entities`, or `.Core`.

#### Why `.Domain` and not `.Model`

`Domain` is the near-universal name in the .NET ecosystem, and `Model` is actively ambiguous:

| Reference | Project name | Contents |
|---|---|---|
| [Microsoft Learn / eShopOnContainers](https://learn.microsoft.com/en-us/dotnet/architecture/microservices/microservice-ddd-cqrs-patterns/ddd-oriented-microservice) | `Ordering.Domain` | entities, value objects, domain services, domain events, repository interfaces |
| [Jason Taylor Clean Architecture template](https://jasontaylor.dev/clean-architecture-getting-started/) | `Domain` | "entities, enums, exceptions, interfaces, types and logic specific to the domain layer" |
| [Ardalis Clean Architecture template](https://ardalis.github.io/CleanArchitecture/getting-started/) | `Core` | entities, aggregates, value objects, domain events, specifications |
| ABP Framework | `{Project}.Domain` | same |

Nobody ships a project called `.Model`, and nobody splits entities away from domain behaviour into a second assembly. More importantly, **"Model" is an overloaded word specifically in .NET**: ASP.NET MVC ships a `Models` folder whose conventional contents are *view models and input/binding models*, not domain entities — so a project named `Ploch.Crawler.Model` reads ambiguously to any .NET developer or coding agent ([The Three Models of ASP.NET MVC Apps](https://www.red-gate.com/simple-talk/development/dotnet-development/the-three-models-of-asp-net-mvc-apps/)). `Domain` has no such collision, and it stays correct when entities later gain behaviour.

`Entities` is a **folder inside** `.Domain`, never a project of its own — same for `ValueObjects/`, `Events/`, `Services/`.

#### `.Domain` (the layer) vs `Ploch.Data.Model` (the package) — not the same thing

This distinction matters and is easy to get wrong. **`Ploch.Data.Model` is a published, shared library of model *contracts*** — the marker interfaces (`IHasId<TId>`, `INamed`, `IHasAuditProperties`) that entities implement so `Ploch.Data.GenericRepository` can operate on them generically. It keeps its name; it is not an app's domain layer and must never be renamed as part of a `.Domain` migration.

An application's `.Domain` project *consumes* that package. `ploch-data`'s own sample app shows both in one file:

```xml
<!-- Ploch.Data.SampleApp.Model.csproj — the app's entity project (renames to .Domain) -->
<PackageReference Include="Ploch.Data.Model" />   <!-- the contracts package (keeps its name) -->
```

#### Architecture note: this is an anemic domain, and that is deliberate

As currently written, entities in both worked examples are plain data carriers — `{ get; set; }` auto-properties, no invariant enforcement (nothing stops `run.Status = Completed` alongside `run.PagesFetched = -5`), with business rules living in `.UseCases`. In DDD terms that is an **anemic model with an application service layer** (transaction-script style), not a rich domain model. That is a legitimate and appropriate choice for apps of this size, and it is what the workspace does today — the doc names it here so that nobody mistakes the layering for full DDD and starts bolting aggregates onto it. The `.Domain` name is still the right one: it is where invariant-enforcing behaviour goes *if and when* an app earns it, with no project rename at that point.

> **Migration in progress.** The rename from `.Model`/`.Models`/`.DomainModel` to `.Domain` is tracked by one GitHub issue per affected repository. Until those land, the code excerpts quoted later in this document still show the old `Model/` directory and `.Model` project names, because they are verbatim from the current source. The **standard** is `.Domain`; the **excerpts** are pre-migration reality.

### 3.2 Data Access

| Layer | Project | Contains |
|---|---|---|
| `.Data` | `Ploch.{Product}[.{Area}].Data` | `DbContext`, `IEntityTypeConfiguration<>` classes, provider-agnostic DI registration. |
| `.Data.{Provider}` | `Ploch.{Product}[.{Area}].Data.{Provider}` | Design-time factory, EF Core migrations, provider-specific connection configuration. |

`.Data` never references a specific ADO.NET provider package — that dependency belongs entirely in `.Data.{Provider}`, so a repo can add or swap providers by adding or removing one project. `ploch-crawler` demonstrates this: `Ploch.Crawler.Data` references only `Microsoft.EntityFrameworkCore`/`.Relational`, and `Ploch.Crawler.Data.PostgreSql` is the only *library* project that references `Npgsql.EntityFrameworkCore.PostgreSQL`. `ConfigTracker` demonstrates the multi-provider case: one `.Data` project, two sibling provider projects (`.Data.SQLite` and `.Data.SqlServer`) that can be swapped by changing which one the host references (see [§5.3](#53-plochdata-usage)).

> **Divergence in the reference code:** `Ploch.Crawler.UI.ConsoleApp` *also* declares `Npgsql.EntityFrameworkCore.PostgreSQL` directly (visible in its `.csproj` in [§5.5](#55-full-csproj-reference--ploch-crawler)). That reference is redundant — the host already gets the provider transitively through `.Data.PostgreSql` — and it undercuts the split, because the host now names a database provider it should not need to know about. **Templates must not copy it**; the crawler should drop it.

Canonical provider qualifiers: `PostgreSql`, `SQLite`, `SqlServer` — see [§4](#4-casing-and-spelling) for exact casing.

### 3.3 Application

| Layer | Project | Contains |
|---|---|---|
| `.UseCases` | `Ploch.{Product}[.{Area}].UseCases` | Application-layer orchestration: use-case classes, pipelines, mapping, DTOs. |
| `.Abstractions` | `Ploch.{Product}[.{Area}].{Layer}.Abstractions` | Interfaces/contracts extracted so a consumer can depend on them without the implementation. |

`.UseCases` is the single application layer name — never `Core`, `Services`, `Business`, `Logic`, `Processing`, or `Handlers`. `Ploch.Crawler.UseCases` is the largest project in the crawler example: it holds the crawl pipeline, robots.txt handling, URL normalisation, HTML analysis, and email extraction — all pure logic with **no EF Core dependency**. `.Data` references `.UseCases` (for the `ICrawlStore` contract it implements), not the other way around — the use-case layer defines the contracts it needs from persistence, and the data layer fulfils them. That inversion is deliberate: it is what makes `UseCases.Tests` runnable with an in-memory fake store and no database at all (see [§6](#6-testing-standards)).

`.Abstractions` is a **qualifier on a layer**, never a layer of its own — `Ploch.{Product}.UseCases.Abstractions`, not `Ploch.{Product}.Abstractions`. Prefer it over `.Interfaces`.

### 3.4 Presentation — the `.UI.` Group

Every user-facing presentation project lives under a `.UI.` segment, followed by the technology. `UI` is a group, never a leaf project on its own.

```text
Ploch.{Product}[.{Area}].UI.{Technology}
```

| Project | Contains |
|---|---|
| `.UI.ConsoleApp` | Console / CLI application host |
| `.UI.Web` | Blazor, MVC, or Razor Pages web UI host |
| `.UI.Maui` | .NET MAUI application host |
| `.UI.WinUI` | WinUI 3 desktop host |
| `.UI.Wpf` | WPF desktop host |
| `.UI.Shared` | ViewModels/presentation logic shared across all UI technologies of the product |

`Ploch.Crawler.UI.ConsoleApp` is the live example — the only *source* project with `OutputType=Exe`. (Both test projects set it too: xUnit v3's Microsoft Testing Platform runner needs an executable host, so `OutputType=Exe` is not by itself a marker of an application host.) **Never drop the `.UI.` segment**, and **never repeat "UI" inside the technology name** (`UI.ConsoleUI` stutters; `UI.ConsoleApp` is correct). The technology segment must also not shadow a BCL type — this is why the console host is `ConsoleApp`, not `Console` (see [§4.1](#41-names-that-collide)).

### 3.5 Services — the `.Api.` Group

Every service-facing project lives under a `.Api.` segment, following the same group-never-leaf rule as `.UI.`.

| Project | Contains |
|---|---|
| `.Api.WebApi` | HTTP/REST host |
| `.Api.GraphQL` | GraphQL host |
| `.Api.Grpc` | gRPC service host |
| `.Api.Contracts` | Request/response DTOs, published for consumers — the **only** `.Api.*` project other code may reference |
| `.Api.Client` | Client for **this product's own** API — a client for someone else's API is `.Infrastructure.{Service}` instead |

> **Provisional — not yet validated.** Unlike every other section here, `.Api.*` is backed by **neither a worked example in this workspace nor an external citation**: no MrPloch repo currently ships an API surface. It is a forward-looking extrapolation of the `.UI.` group rule to service hosts, recorded so template work has a starting point. **Treat it as a proposal, not a settled rule** — validate it against a real API project before generating templates from it, and expect it to change. Every other layer in [§3](#3-canonical-layers) meets the evidence bar; this one does not yet.

### 3.6 Cross-Cutting and Other Hosts

| Layer | Project | Contains |
|---|---|---|
| `.Common` | `Ploch.{Product}[.{Area}].Common` | Helpers shared by two or more layers **within this product**. If it's useful outside the product, it belongs in `ploch-common` instead. |
| `.Infrastructure` | `Ploch.{Product}[.{Area}].Infrastructure` | Adapters to external systems: file system, OS APIs, third-party HTTP clients, message brokers. **Not** domain services, events or invariants — those are `.Domain`. |
| `.Worker` | `Ploch.{Product}[.{Area}].Worker` | Background/hosted-service worker with no UI or API surface. |
| `.Functions` | `Ploch.{Product}[.{Area}].Functions` | Azure Functions / serverless host. |

**Deliberate divergence from standard Clean Architecture:** the reference layering puts the `DbContext`, repository implementations *and* external-system adapters together in a single `Infrastructure` project. This workspace splits them — `.Data` for EF Core persistence, `.Infrastructure` for everything else external. That is a conscious choice (persistence churns for different reasons, and on a different release cadence, than a third-party HTTP client), not an oversight. The dependency direction is unchanged and still points inward: both `.Data` and `.Infrastructure` may depend on `.Domain` and `.UseCases`; neither may be depended upon by them.

---

## 4. Casing and Spelling

| Token | Correct | Wrong |
|---|---|---|
| PostgreSQL | `PostgreSql` | `Postgres`, `PostgreSQL` |
| SQLite | `SQLite` | `SqLite`, `Sqlite` |
| SQL Server | `SqlServer` | `SQLServer`, `MSSQL` |
| Web API | `Api` (segment), `WebApi` (host) | `API`, `WEBAPI` |
| EF Core | `EFCore` | `EfCore`, `EntityFrameworkCore` |

### Acronym casing

1. **Two-letter acronyms are fully capitalised** — `IO`, `DB`, `UI`.
2. **Three-or-more-letter acronyms are PascalCased** — `Xml`, `Json`, `Sql`, `Api`, `Grpc`.
3. **Brand casing overrides both**, where the vendor defines one — `SQLite` is the vendor's own spelling and is kept as-is.

**`PostgreSql` is a deliberate exception to rule 3, not an application of it.** The vendor spells it `PostgreSQL`, and so does the NuGet package (`Npgsql.EntityFrameworkCore.PostgreSQL`). This workspace nonetheless uses **`PostgreSql`** as the project qualifier, applying the three-plus-letter acronym rule (rule 2) for consistency with the sibling `SqlServer` qualifier. The **package** keeps its published casing; the **project qualifier** uses ours. This is a house convention chosen over the brand spelling — recorded here so nobody "fixes" it in either direction.

### Other rules

- **PascalCase every segment.** No hyphens, underscores, or spaces in project or directory names.
- **No abbreviations.** `Utilities` not `Utils`, `Configuration` not `Config`. Widely accepted acronyms (`Api`, `UI`, `Db`) are the exception.
- **No version or TFM in a project name.** Both worked examples get their target framework from a single `<TargetFrameworkVersion>net10.0</TargetFrameworkVersion>` property in the repo's `Directory.Build.props`, referenced by every `.csproj` as `<TargetFramework>$(TargetFrameworkVersion)</TargetFramework>` — never hardcoded per project, and never encoded into the project name.

### 4.1 Names That Collide

C# resolves a namespace segment ahead of a type of the same name. Inside `namespace Ploch.MyApp.UI.Console`, `Console.WriteLine(...)` resolves to the *namespace*, not `System.Console` — every call site would need `global::System.Console` to compile. Never use these as a segment: `Console`, `Task`, `Path`, `File`, `Timer`, `Type`, `Environment`, `Action`, `Stream`, `Version`, `Index`, `Range`, `Uri`, `Host`, `Application`, `Window`, `Page`.

This is the concrete reason the console host is named `UI.ConsoleApp`, not `UI.Console` — `ploch-crawler`'s `Program.cs` calls `AppBuilder.Create(args)` from `Ploch.CommandLine.Spectre`, and every file in that project would otherwise need to fully qualify `System.Console` for any diagnostic output.

An entity in `.Domain` must not be named `Task`, `File`, `Event`, `Type`, or `Version` either — qualify with the domain (`WorkItem`, `TrackedFile`, `AuditEvent`).

---

## 5. Application Archetype: Console App with Data Access

This is the archetype both worked examples implement. It is the starting point for the `dotnet new` template and the GitHub repository template for any new command-line tool that needs persistence.

### 5.1 Project Graph

```text
                          ┌──────────────────┐
                          │  .UI.ConsoleApp  │  (Exe — references everything below)
                          └────────┬─────────┘
                     ┌─────────────┴─────────────┐
                     │                           │
                     ▼                           ▼
            ┌──────────────────┐      ┌──────────────────────┐
            │    .UseCases     │      │  .Data.{Provider}    │
            │   (pure logic;   │      │  (EF Core provider,  │
            │  defines the     │      │   migrations)        │
            │  persistence     │      └──────────┬───────────┘
            │  contracts)      │                 │
            └──────────────────┘                 ▼
                     ▲   ▲             ┌──────────────────────┐
                     │   │             │        .Data         │
                     │   └─────────────┤  (DbContext, entity  │
                     │   implements    │   configurations)    │
                     │   ICrawlStore   └──────────┬───────────┘
                     │                            │
                     └──────────┐      ┌──────────┘
                                ▼      ▼
                          ┌──────────────────┐
                          │     .Domain      │
                          └──────────────────┘
```

Read the diagram's `.Data → .UseCases` arrow carefully: it points **up**, not down. `.Data` depends on `.UseCases` to implement a contract `.UseCases` defines (`ICrawlStore` in the crawler example) — `.UseCases` never references `.Data` or any EF Core package. This is the Dependency Inversion Principle applied at the project level, and it is what lets `.UseCases.Tests` run with zero database dependency.

### 5.2 `Ploch.Common` Usage

`Ploch.Common` is the workspace's shared cross-cutting library. Three of its facilities are org-wide conventions, not optional conveniences.

#### 5.2.1 Argument checking — `myVar.NotNull()`, never `ArgumentNullException.ThrowIfNull(myVar)`

**This is a mandatory MrPloch convention.** All argument and state validation uses the extension methods in the `Ploch.Common.ArgumentChecking` namespace, in preference to the BCL `ThrowIf*` static helpers or hand-written `if (x is null) throw`.

```csharp
using Ploch.Common.ArgumentChecking;

// ✗ Do not
ArgumentNullException.ThrowIfNull(options);
ArgumentOutOfRangeException.ThrowIfLessThan(maxWorkers, 1, nameof(maxWorkers));
var cs = configuration.GetConnectionString("DefaultConnection")
         ?? throw new InvalidOperationException("ConnectionStrings:DefaultConnection is missing.");

// ✓ Do
options.NotNull();
maxWorkers.Positive();
var cs = configuration.GetConnectionString("DefaultConnection").RequiredNotNullOrEmpty();
```

**Why the extension form.** It reads left-to-right in the same direction as the data flows, it **returns the validated value** so it composes into an assignment or an expression body, and — critically — the argument-fault and required-state cases are *different methods* rather than the same method plus a hand-written `?? throw`, so the intended exception type is chosen deliberately instead of by accident.

**The parameter name is captured automatically — on `net7.0+`.** The `net7.0+` overloads take the name parameter as `[CallerArgumentExpression]`, so you write `myVar.NotNull()` with **no arguments**. There, `myVar.NotNull(nameof(myVar))` is not merely redundant — it silently drifts when the variable is renamed.

This covers application projects, which target `net10.0`. It does **not** hold org-wide: shared libraries in `ploch-common` and `ploch-data` multi-target down to `netstandard2.0`, and configuration in this repository still targets `net8.0` (`repository-config/console-apps/Directory.Build.props`) and `net9.0`. On a `netstandard2.0` target the `[CallerArgumentExpression]` overload is unavailable and the explicit name argument is **required**: `myVar.NotNull(nameof(myVar))`. Check the project's effective TFM before assuming the no-argument form compiles.

##### The `NotNull` / `RequiredNotNull` distinction

This is the part that is easy to get wrong, and it is the reason this convention exists at all:

| Situation | Method | Throws |
|---|---|---|
| A **caller passed** something invalid — the caller's fault | `NotNull()`, `NotNullOrEmpty()`, `Positive()`, `NotOutOfRange()` | `ArgumentNullException` / `ArgumentException` / `ArgumentOutOfRangeException` |
| **Required state** is missing — configuration, environment, an unset dependency; nobody passed a bad argument | `RequiredNotNull()`, `RequiredNotNullOrEmpty()`, `RequiredTrue()`, `RequiredFalse()` | `InvalidOperationException` |

A missing connection string in `appsettings.json` is **not** an `ArgumentNullException` — no argument was passed. It is `RequiredNotNullOrEmpty()`.

##### Full API surface — `Ploch.Common.ArgumentChecking`

| Method | Throws | Use for |
|---|---|---|
| `NotNull()` | `ArgumentNullException` | Any reference or nullable value-type argument |
| `NotNullOrEmpty()` | `ArgumentNullException` / `ArgumentException` | `string` and `IEnumerable<T>` arguments |
| `NotNullOrDefault()` | `ArgumentException` | Value-type arguments that must not be `default` |
| `Positive()` | `ArgumentOutOfRangeException` | Numeric arguments that must be > 0 |
| `NotOutOfRange<TEnum>()` | `ArgumentOutOfRangeException` | Enum arguments — rejects undefined values |
| `AssignableTo<TTarget>()` / `AssignableToOrNull<TTarget>()` | `ArgumentException` | `Type` arguments that must be assignable to a target |
| `RequiredNotNull()` | `InvalidOperationException` | Required state, not an argument |
| `RequiredNotNullOrEmpty()` | `InvalidOperationException` | Required string/collection state |
| `RequiredTrue()` / `RequiredFalse()` | `InvalidOperationException` | A required condition on internal state |

Path validation lives alongside it in `PathGuard`, but **the pairing is not clean there** and the difference matters. `IsValidPath()` and `EnsureFileExists()` throw `ArgumentException`. `RequiredIsValidPath()` and `RequiredFileExists()` throw `InvalidOperationException` only for *their own* failure condition — `RequiredFileExists()` is implemented as `File.Exists(path.IsValidPath(parameterName))`, so a null, empty, or malformed path throws `ArgumentException` from the inner `IsValidPath()` call, and only a **syntactically valid path that does not exist** reaches the `InvalidOperationException`. If you need required-state semantics for a possibly-null path, call `RequiredNotNullOrEmpty()` on it first.

> **`Ploch.Common.DawnGuard` is deprecated.** Its API is `[Obsolete]` and it exists only to add type guards over the third-party `Dawn.Guard` package. Do not add it to a new project; `ArgumentChecking` supersedes it with no external dependency. Migrate `Guard.Argument(x).NotNull()` call sites to `x.NotNull()`.
>
> **Known gap:** `ploch-crawler` currently uses the BCL form in 44 call sites across `.UseCases`, `.Data` and `.Data.PostgreSql`, plus a `?? throw new InvalidOperationException(...)` in `UI.ConsoleApp/Program.cs`. The project already references `Ploch.Common`, so these are pure call-site changes with no new dependency. This gap is recorded here rather than silently omitted, because this document is generated from what is actually true today.

#### 5.2.2 Modular DI registration — `ServicesBundle`

For anything beyond a single `AddX()` extension method, use the `ServicesBundle` pattern from `Ploch.Common.DependencyInjection`: a bundle overrides `Dependencies` to declare registration ordering and implements `DoConfigure()`. Register with `services.AddServicesBundle(bundle, configuration)`. Variants: `ConfigurableServicesBundle`, `DelegatingServicesBundle`.

#### 5.2.3 Pluggable serialization — `ISerializer`

Depend on `ISerializer` / `ISerializer<TSettings>` (`Ploch.Common.Serialization`) rather than taking a hard dependency on `System.Text.Json` or `Newtonsoft.Json` directly. Both implementations ship with their own DI `ServicesBundle` (`…SystemTextJson.ExtensionsDependencyInjection`, `…NewtonsoftJson.ExtensionsDependencyInjection`).

### 5.3 `Ploch.Data` Usage

Both examples build their data layer on `Ploch.Data`, specifically:

- **`Ploch.Data.Model`** — the model-layer marker interfaces every entity implements. `Site : IHasId<int>`, `CrawlRun : IHasId<int>, IHasCreatedTime` (`ploch-crawler`); the same pattern in `ConfigTracker`'s entities. Implementing these interfaces, rather than hand-rolling an `Id`/`CreatedTime` property, is what lets `Ploch.Data.GenericRepository` operate on any entity generically.
- **`Ploch.Data.EFCore`** — `BaseDbContextFactory<TContext, TFactory>` for design-time factories, `IDbContextCreationLifecycle` for provider-specific hooks into `OnModelCreating`/`OnConfiguring` (both examples' `DbContext` classes take this as a constructor parameter rather than hardcoding provider setup inline).
- **`Ploch.Data.GenericRepository.EFCore`** — the generic repository and `IUnitOfWork` (the full consumption rules live with the library, in [`mrploch/ploch-data`](https://github.com/mrploch/ploch-data) under `src/Data.GenericRepository/README.md`; there is no `data-access.md` in this repository). `services.AddDbContextWithRepositories<TContext>(...)` registers the `DbContext`, every repository interface, and `IUnitOfWork` in one call. `ploch-crawler`'s `AddCrawlerData` extension method wraps exactly this call.
- **Provider packages follow `.EFCore.{Provider}` naming**: `Ploch.Data.GenericRepository.EFCore.SqLite`, `Ploch.Data.GenericRepository.EFCore.SqlServer`. Note these published packages spell it **`SqLite`**, which [§4](#4-casing-and-spelling) lists as wrong for *new* project qualifiers (`SQLite`). They are a **grandfathered legacy exception** — a published package ID cannot be renamed without breaking consumers. Do not cite them as precedent for a new project, and do not "correct" them.

**Database provider swapping** is the point of separating `.Data` from `.Data.{Provider}`. `ConfigTracker` demonstrates it directly: `ServiceCollectionRegistrations.cs` inside its `Shared/` folder is **not its own project** — it is a single source file **linked** (via `<Compile Include="..\Shared\...\" Link="..." />`) into *both* `Data.SQLite.csproj` and `Data.SqlServer.csproj`. Both provider assemblies therefore expose the same namespace, class name, and method signatures, and switching which database `ConfigTracker` uses is a `ProjectReference` change with **zero code change** at the call site. `ploch-crawler`, needing only one provider so far, keeps its registration directly inside `Ploch.Crawler.Data.PostgreSql`'s own `ServiceCollectionRegistrations.cs` instead — the linked-file trick is worth the extra indirection only once a second provider actually exists.

### 5.4 The Console Host — `Ploch.CommandLine.Spectre`

The `.UI.ConsoleApp` project hosts the application using `Ploch.CommandLine.Spectre`'s `AppBuilder`, which wraps `Microsoft.Extensions.Hosting` with `Spectre.Console.Cli`: configuration (`appsettings.json`), dependency injection, Serilog logging, and Ctrl+C handling all come from the host, so `Program.cs` only wires up commands and DI registrations. `ploch-crawler`'s `Program.cs`:

```csharp
return await AppBuilder.Create(args)
                       .WithName("ploch-crawler")
                       .WithDescription("Crawls websites and collects the email addresses they expose into PostgreSQL.")
                       .WithVersion(new Version(0, 1, 0))
                       .ConfigureServices((context, services) =>
                                          {
                                              var connectionString = context.Configuration.GetConnectionString("DefaultConnection")
                                                  ?? throw new InvalidOperationException("ConnectionStrings:DefaultConnection is missing from appsettings.json.");

                                              services.AddCrawlerPostgreSql(connectionString, context.Configuration);
                                              services.AddCrawlerUseCases();
                                          })
                       .ConfigureCommandApp(config =>
                                            {
                                                config.Settings.ApplicationName = "ploch-crawler";
                                                config.AddCommand<CrawlCommand>("crawl")
                                                      .WithDescription("Crawl seed websites and collect email addresses.");
                                                // ...additional commands, one per Spectre.Console.Cli ICommand
                                            })
                       .RunAsync(args);
```

Each command is its own class under `Commands/`, following the `{Verb}Command` naming pattern (`CrawlCommand`, `StatsCommand`, `ExportCommand`, `MigrateCommand`). Sub-branches of related commands use `config.AddBranch<TSettings>(...)` (the crawler's `db migrate` sub-command).

### 5.5 Full `.csproj` Reference — `ploch-crawler`

Every project in the archetype, exactly as it exists in the repository (bin/obj-relative paths trimmed for readability):

**`.Model`** (no framework dependency beyond `Ploch.Data.Model`):

```xml
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <TargetFramework>$(TargetFrameworkVersion)</TargetFramework>
  </PropertyGroup>
  <ItemGroup>
    <ProjectReference Include="..\..\..\ploch-data\src\Data.Model\Ploch.Data.Model.csproj" />
  </ItemGroup>
</Project>
```

**`.UseCases`** (pure logic; references `.Model` and `Ploch.Common`, never EF Core):

```xml
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <TargetFramework>$(TargetFrameworkVersion)</TargetFramework>
  </PropertyGroup>
  <ItemGroup>
    <PackageReference Include="AngleSharp" />
    <PackageReference Include="Microsoft.Extensions.DependencyInjection.Abstractions" />
    <PackageReference Include="Microsoft.Extensions.Logging.Abstractions" />
  </ItemGroup>
  <ItemGroup>
    <ProjectReference Include="..\Model\Ploch.Crawler.Model.csproj" />
    <ProjectReference Include="..\..\..\ploch-common\src\Common\Ploch.Common.csproj" />
  </ItemGroup>
</Project>
```

**`.Data`** (provider-agnostic; references `.UseCases` to *implement* its contracts):

```xml
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <TargetFramework>$(TargetFrameworkVersion)</TargetFramework>
  </PropertyGroup>
  <ItemGroup>
    <PackageReference Include="Microsoft.EntityFrameworkCore" />
    <PackageReference Include="Microsoft.EntityFrameworkCore.Relational" />
  </ItemGroup>
  <ItemGroup>
    <ProjectReference Include="..\Model\Ploch.Crawler.Model.csproj" />
    <ProjectReference Include="..\UseCases\Ploch.Crawler.UseCases.csproj" />
    <ProjectReference Include="..\..\..\ploch-data\src\Data.EFCore\Ploch.Data.EFCore.csproj" />
    <ProjectReference Include="..\..\..\ploch-data\src\Data.GenericRepository\Data.GenericRepository.EFCore\Ploch.Data.GenericRepository.EFCore.csproj" />
  </ItemGroup>
</Project>
```

**`.Data.PostgreSql`** (the only project referencing the ADO.NET provider; owns migrations):

```xml
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <TargetFramework>$(TargetFrameworkVersion)</TargetFramework>
  </PropertyGroup>
  <ItemGroup>
    <PackageReference Include="Npgsql.EntityFrameworkCore.PostgreSQL" />
    <PackageReference Include="Microsoft.EntityFrameworkCore.Design">
      <PrivateAssets>all</PrivateAssets>
      <IncludeAssets>runtime; build; native; contentfiles; analyzers; buildtransitive</IncludeAssets>
    </PackageReference>
    <PackageReference Include="Microsoft.EntityFrameworkCore.Tools">
      <PrivateAssets>all</PrivateAssets>
      <IncludeAssets>runtime; build; native; contentfiles; analyzers; buildtransitive</IncludeAssets>
    </PackageReference>
  </ItemGroup>
  <ItemGroup>
    <ProjectReference Include="..\Data\Ploch.Crawler.Data.csproj" />
    <ProjectReference Include="..\..\..\ploch-data\src\Data.EFCore\Ploch.Data.EFCore.csproj" />
  </ItemGroup>
  <ItemGroup>
    <None Update="appsettings.json" CopyToOutputDirectory="PreserveNewest" />
  </ItemGroup>
</Project>
```

**`.UI.ConsoleApp`** (the executable; the only project with `OutputType=Exe`):

```xml
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <OutputType>Exe</OutputType>
    <TargetFramework>$(TargetFrameworkVersion)</TargetFramework>
  </PropertyGroup>
  <ItemGroup>
    <PackageReference Include="Microsoft.Extensions.Hosting" />
    <PackageReference Include="Npgsql.EntityFrameworkCore.PostgreSQL" />
    <PackageReference Include="CsvHelper" />
  </ItemGroup>
  <ItemGroup>
    <ProjectReference Include="..\Data.PostgreSql\Ploch.Crawler.Data.PostgreSql.csproj" />
    <ProjectReference Include="..\UseCases\Ploch.Crawler.UseCases.csproj" />
    <ProjectReference Include="..\..\..\ploch-commandline\src\Spectre\CommandLine.Spectre\Ploch.CommandLine.Spectre.csproj" />
  </ItemGroup>
  <ItemGroup>
    <None Update="appsettings.json" CopyToOutputDirectory="PreserveNewest" />
  </ItemGroup>
</Project>
```

### 5.6 Repository-Level Build Configuration

`Directory.Build.props` sets everything project-level configuration should not repeat:

```xml
<Project>
  <PropertyGroup>
    <Authors>Kris Ploch</Authors>
    <Company>Ploch</Company>
    <Product>Ploch.Crawler</Product>
    <TargetFrameworkVersion>net10.0</TargetFrameworkVersion>
    <Nullable>enable</Nullable>
    <ImplicitUsings>enable</ImplicitUsings>
    <EnforceCodeStyleInBuild>true</EnforceCodeStyleInBuild>
    <EnableNETAnalyzers>true</EnableNETAnalyzers>
    <AnalysisLevel>latest-Recommended</AnalysisLevel>
    <IsTestProject>$(MSBuildProjectName.EndsWith('Tests'))</IsTestProject>
    <IsPackable>false</IsPackable>
    <GeneratePackageOnBuild>false</GeneratePackageOnBuild>
  </PropertyGroup>
  <PropertyGroup Condition="$(IsTestProject)">
    <GenerateDocumentationFile>false</GenerateDocumentationFile>
  </PropertyGroup>
  <ItemGroup Condition="$(IsTestProject)">
    <Using Include="Xunit" />
    <Using Include="FluentAssertions" />
    <PackageReference Include="coverlet.msbuild">
      <PrivateAssets>all</PrivateAssets>
    </PackageReference>
    <PackageReference Include="coverlet.collector">
      <PrivateAssets>all</PrivateAssets>
    </PackageReference>
  </ItemGroup>
  <PropertyGroup Condition="!$(IsTestProject)">
    <GenerateDocumentationFile>true</GenerateDocumentationFile>
  </PropertyGroup>
</Project>
```

Note the `<Using Include="Xunit" />` / `<Using Include="FluentAssertions" />` global usings applied only to test projects — every test file gets `Xunit` and `FluentAssertions` types without a per-file `using`.

`Directory.Packages.props` uses Central Package Management and imports the shared version sets from `mrploch-development/dependencies/`:

```xml
<Project>
  <PropertyGroup>
    <ManagePackageVersionsCentrally>true</ManagePackageVersionsCentrally>
  </PropertyGroup>
  <Import Project="../mrploch-development/dependencies/MicrosoftExtensions.Net9.Packages.props" />
  <Import Project="../mrploch-development/dependencies/Common.Packages.props" />
  <Import Project="../mrploch-development/dependencies/Serilog.Logging.Packages.props" />
  <Import Project="../mrploch-development/dependencies/Spectre.Console.Packages.props" />
  <Import Project="../mrploch-development/dependencies/Testing.Packages.props" />
  <Import Project="../mrploch-development/dependencies/Analyzers.Global.Packages.props" />
  <ItemGroup>
    <!-- Only this repo's app-specific packages need an explicit version here. -->
    <PackageVersion Include="Npgsql.EntityFrameworkCore.PostgreSQL" Version="10.0.3" />
    <PackageVersion Include="AngleSharp" Version="1.7.3" />
    <PackageVersion Include="Testcontainers.PostgreSql" Version="4.14.0" />
  </ItemGroup>
</Project>
```

Any new console-app-with-data-access repo should import the same six `mrploch-development/dependencies/*.props` files and add only its own app-specific package versions on top.

---

## 6. Testing Standards

### 6.1 Frameworks

| Concern | Library | Notes |
|---|---|---|
| Test framework | **xUnit v3** (`xunit.v3` + `xunit.runner.visualstudio`) | Not xUnit v2. Both `Ploch.Crawler.UseCases.Tests.csproj` and its integration-test sibling reference `xunit.v3` explicitly. |
| Assertions | **FluentAssertions** | Global-usinged into every test project via `Directory.Build.props` — no per-file `using FluentAssertions;` needed. |
| Object generation | **AutoFixture** (+ `AutoFixture.Xunit3` for `[AutoData]`) | Referenced in the archetype's unit-test project as standard practice, for generating test data without hand-built object graphs. |
| Integration DB fixtures | **Testcontainers** — `Testcontainers.PostgreSql`, `Testcontainers.MsSql` | Spins up a real, disposable database container per test run — see `PostgresFixture.cs` in the crawler's integration tests. **There is no Testcontainers module for SQLite** and none is needed: SQLite is in-process, so an integration test uses a temporary file or an in-memory database directly instead of a container. |
| Coverage | **Coverlet** (`coverlet.msbuild` + `coverlet.collector`) | Wired at the repo level in `Directory.Build.props`, not per test project. |

### 6.2 Test Project Naming and Location

| Kind | Name | Directory |
|---|---|---|
| Unit | `{ProjectUnderTest}.Tests` | `tests/{Dir}.Tests/` |
| Integration | `{ProjectUnderTest}.IntegrationTests` | `tests/{Dir}.IntegrationTests/` |

Both examples follow this exactly:

- `Ploch.Crawler.UseCases.Tests` — pure unit tests for the `.UseCases` layer, no database. Uses an in-memory `InMemoryCrawlStore` test double (`TestSupport/`) to satisfy `ICrawlStore` instead of a real `.Data` project, which is only possible because `.UseCases` never references `.Data` (see [§5.1](#51-project-graph)).
- `Ploch.Crawler.Data.PostgreSql.IntegrationTests` — integration tests against a real, disposable PostgreSQL container via Testcontainers, including a `MigrationsTests.cs` that verifies migrations actually apply.
- `Ploch.AI.ConfigTracker.Model.Tests` and `Ploch.AI.ConfigTracker.Data.IntegrationTests` — the same split in the multi-project repo, with the `{Area}` directory level preserved: `tests/ConfigTracker/Model.Tests/`.

Test **class and method** naming (the `<Member>_should_<expected behaviour>` convention, `Arrange`/`Act`/`Assert` structure) is governed by the workspace's `.NET Testing Standards` rule and applies identically regardless of repository shape. Example, from `Ploch.Crawler.UseCases.Tests`:

```csharp
public class UrlNormalizerTests
{
    [Theory]
    [InlineData("HTTP://Example.COM:80/A?b=1#frag", "http://example.com/A?b=1")]
    [InlineData("https://example.com", "https://example.com/")]
    public void Normalize_should_produce_canonical_absolute_url(string input, string expected) =>
        UrlNormalizer.Normalize(input, Base)!.AbsoluteUri.Should().Be(expected);

    [Fact]
    public void Normalize_should_return_null_for_relative_input_without_base() =>
        UrlNormalizer.Normalize("/about").Should().BeNull();
}
```

### 6.3 Testing Argument Validation

Guard clauses are behaviour and are tested like any other behaviour — the exception *type* is part of the public contract, and the `NotNull` / `RequiredNotNull` split in [§5.2.1](#521-argument-checking--myvarnotnull-never-argumentnullexceptionthrowifnullmyvar) only pays off if tests assert the right one.

```csharp
[Fact]
public void Constructor_should_throw_when_options_is_null() =>
    FluentActions.Invoking(() => new PageFetcher(handler, null!, logger))
                 .Should().Throw<ArgumentNullException>()
                 .WithParameterName("options");   // proves CallerArgumentExpression captured the name

// Required state: the connection string is ABSENT FROM CONFIGURATION — nobody passed a bad
// argument, so this must be InvalidOperationException, not ArgumentNullException.
[Fact]
public void AddCrawlerPostgreSql_should_throw_when_connection_string_is_not_configured()
{
    var configuration = new ConfigurationBuilder().Build();   // no ConnectionStrings section at all

    FluentActions.Invoking(() => services.AddCrawlerPostgreSql(configuration))
                 .Should().Throw<InvalidOperationException>();
}
```

Note what the second test does **not** do: passing `null!` directly as a `connectionString` parameter would be a *caller* fault and must throw `ArgumentNullException`. To exercise the required-state path you have to make the **state** missing — an empty configuration — not hand the method a null argument. Getting this wrong in a test is the easiest way to enshrine the wrong exception type in the contract.

`.WithParameterName(...)` is worth asserting on at least one call site per type: it is what catches a stray `myVar.NotNull(nameof(otherVar))` or an explicit name left behind after a rename.

Argument-validation tests belong in the **unit** test project for the layer that owns the type — they need no database and no container.

### 6.4 Cross-Test-Project Sharing

The integration-test project may reference the unit-test project when it needs to reuse a test double, rather than duplicating it:

```xml
<!-- Ploch.Crawler.Data.PostgreSql.IntegrationTests.csproj -->
<ProjectReference Include="..\UseCases.Tests\Ploch.Crawler.UseCases.Tests.csproj" />
```

This is how the crawler's integration tests reuse the unit tests' `StubHttpMessageHandler` without a third `TestingSupport` project — acceptable for a two-test-project repo; once a third consumer appears, promote the shared fixtures into a dedicated `Ploch.{Product}.TestingSupport` project under `tests/` instead. `TestingSupport` is a **test-tree project kind**, not one of the [§3](#3-canonical-layers) source layers — the closed layer set governs `src/` only.

---

## 7. New Project Checklist

Before creating a project in either repository shape:

- [ ] Name matches `Ploch.{Product}[.{Area}].{Layer}[.{Qualifier}]` — `{Area}` present only in a multi-project repository ([§1](#1-repository-shapes)).
- [ ] `{Layer}` is in the canonical set ([§3](#3-canonical-layers)), or a justification is recorded in the repo README.
- [ ] Directory name is the project name minus the `Ploch.{Product}[.{Area}].` prefix, under `src/` or `tests/`.
- [ ] `AssemblyName`, `RootNamespace`, and `PackageId` are **not** set by hand ([§2.1](#21-four-names-one-string)).
- [ ] `TargetFramework` reads `$(TargetFrameworkVersion)` from the repo's `Directory.Build.props` — never hardcoded per project.
- [ ] The domain project is called `.Domain` — exactly one per product/area, never `.Model`, `.Models`, `.DomainModel`, `.Entities`, or `.Core`, and never split into two projects.
- [ ] The published `Ploch.Data.Model` contracts package is referenced, **not** renamed — it is not an app domain layer.
- [ ] `.Data` has no ADO.NET provider package reference; that lives only in `.Data.{Provider}`.
- [ ] `.UseCases` has no EF Core or provider package reference — persistence contracts are defined here and implemented by `.Data`.
- [ ] Provider casing is `SQLite` / `SqlServer` / `PostgreSql`.
- [ ] The console/UI host is `.UI.{Technology}`, never a bare technology name, and does not shadow a BCL type ([§4.1](#41-names-that-collide)).
- [ ] Test projects carry the full prefix (including `{Area}` where applicable) and sit under `tests/`, mirroring the source project's path.
- [ ] Unit tests reference xUnit v3, FluentAssertions (global-usinged), and AutoFixture; integration tests additionally reference Testcontainers for the relevant provider.
- [ ] Argument and state validation uses `Ploch.Common.ArgumentChecking` extensions (`x.NotNull()`), **not** `ArgumentNullException.ThrowIfNull(x)` or a hand-written `?? throw` — and the name argument is omitted so `[CallerArgumentExpression]` supplies it.
- [ ] Required-state failures (missing configuration, unset dependency) use `RequiredNotNull()` / `RequiredNotNullOrEmpty()` and throw `InvalidOperationException`, not `ArgumentNullException`.
- [ ] `Ploch.Common.DawnGuard` is not referenced — it is deprecated in favour of `ArgumentChecking`.
- [ ] The project is added to the repo's `.slnx` solution at a solution folder mirroring its path on disk.
