### Testing Guidelines for Junie (this repository)

These guidelines describe how to add and structure automated tests in this solution so Junie (and contributors) can generate consistent, high‑quality
tests.

#### Goals

- Use the same frameworks, helpers, and conventions already adopted across the solution.
- Keep tests readable, deterministic, and fast.
- Mirror the product structure in test projects and namespaces.

---

### Frameworks and libraries

- xUnit v3
    - Attributes: `Fact`, `Theory`, `InlineData`, `MemberData`, `ClassData`.
    - Many test projects add `<Using Include="Xunit" />` in the test `.csproj` to make xUnit attributes available without explicit `using` statements.
- FluentAssertions
    - For expressive assertions: `result.Should().Be(...)`, `act.Should().Throw<...>()`, etc.
- AutoFixture + AutoMoq + custom attribute
    - Use `Ploch.TestingSupport.XUnit3.AutoMoq.AutoMockDataAttribute` to auto‑create SUTs and mocks.
    - This is referenced via test projects’ project references:
        - `Ploch.TestingSupport.XUnit3.AutoMoq`
        - (Often) `Ploch.TestingSupport.XUnit3`
- JetBrains.Annotations (optional, but used in tests)
    - Attribute `TestSubject` may be applied to test classes to mark the subject under test.

References in example test projects:

- `tests/Common.Tests/Ploch.Common.Tests.csproj`
- `tests/Common.Net9.Tests/Ploch.Common.Net9.Tests.csproj`
- `tests/Storage/Storage.File.Tests/Ploch.Tools.SystemProfiles.Storage.File.Tests.csproj`

---

### Test project setup

- Target framework: typically aligns with repo’s `$(TargetFrameworkVersion)` or set explicitly (e.g., `net10.0`).
- Common `.csproj` patterns:

```xml
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <TargetFramework>net10.0</TargetFramework>
    <ImplicitUsings>enable</ImplicitUsings>
    <Nullable>enable</Nullable>
    <IsPackable>false</IsPackable>
    <OutputType>Exe</OutputType>
  </PropertyGroup>

  <ItemGroup>
    <Using Include="Xunit" />
  </ItemGroup>

  <ItemGroup>
    <!-- Testing helpers used across the solution -->
    <ProjectReference Include="..\..\..\..\ploch-common\src\TestingSupport.FluentAssertions\Ploch.TestingSupport.FluentAssertions.csproj" />
    <ProjectReference Include="..\..\..\..\ploch-common\src\TestingSupport.XUnit3.AutoMoq\Ploch.TestingSupport.XUnit3.AutoMoq.csproj" />
    <!-- Reference the product project under test -->
    <ProjectReference Include="..\..\..\src\<ProductPath>\<Product>.csproj" />
  </ItemGroup>

  <ItemGroup>
    <PackageReference Include="JetBrains.Annotations" />
  </ItemGroup>
</Project>
```

Adjust relative paths to match the local project under test.

---

### Naming and structure conventions

- Project name: mirror product project with `.Tests` suffix.
    - Example: `Ploch.Tools.SystemProfiles.Storage.File` → `Ploch.Tools.SystemProfiles.Storage.File.Tests`.
- Folder layout under `tests` mirrors the `src` structure.
- Namespace mirrors product namespace with `.Tests` suffix.
- Test class names: `<SubjectName>Tests` (e.g., `LocationResolverTests`).
- Test method names: `MethodName_should_expectedBehavior[_when_condition]`.

Examples from `Ploch.Common.Tests` follow these patterns extensively (see `EnumerationConverterTests`).

---

### Test patterns and style

- Prefer Arrange‑Act‑Assert separation with simple comments when clarity helps.
- Use FluentAssertions for assertions.
- For exceptions, capture an `Action` or `Func<T>` (`act`) and assert with `act.Should().Throw<...>()`.
- Use `[Theory]` with `[InlineData]` when validating multiple inputs.
- Use `[AutoMockData]` to auto‑create the SUT and mocks when constructor dependencies exist.
- Keep tests deterministic; avoid time, randomness, ambient state; if needed, abstract such dependencies and inject them (so they can be mocked).

---

### Using AutoFixture + AutoMoq in xUnit v3

```csharp
using Ploch.TestingSupport.XUnit3.AutoMoq; // AutoMockDataAttribute
using Xunit;

public class MyServiceTests
{
    [Theory]
    [AutoMockData]
    public void DoWork_should_call_repository_once(MyService sut, Mock<IMyRepository> repo)
    {
        // Act
        sut.DoWork();

        // Assert
        repo.Verify(r => r.Save(It.IsAny<string>()), Times.Once);
    }
}
```

Note: The `AutoMockDataAttribute` is defined in `Ploch.TestingSupport.XUnit3.AutoMoq` and preconfigures AutoFixture with AutoMoq customization.

---

### FluentAssertions basics

```csharp
result.Should().Be(expected);
collection.Should().Contain(item);
act.Should().Throw<ArgumentException>().Which.ParamName.Should().Be("name");
```

See `tests/Common.Tests/EnumerationConverterTests.cs` for real examples.

---

### Example: testing `LocationResolver`

Product file: `src/Storage/Storage.File/LocationResolver.cs`
Tests project: `tests/Storage/Storage.File.Tests`
Test class: `LocationResolverTests`

```csharp
using JetBrains.Annotations;
using Xunit;

namespace Ploch.Tools.SystemProfiles.Storage.File.Tests;

[TestSubject(typeof(LocationResolver))]
public class LocationResolverTests
{
    [Fact]
    public void ResolveLocation_should_return_same_string_when_no_tokens()
    {
        // Arrange
        var sut = new LocationResolver([]);

        // Act
        var result = sut.ResolveLocation("C:/data/config.json");

        // Assert
        result.Should().EndWith("C:/data/config.json".Replace('/', System.IO.Path.DirectorySeparatorChar));
    }

    [Fact]
    public void ResolveLocation_should_replace_single_token_and_normalize_full_path()
    {
        // Arrange
        var tokens = new[]
        {
            new LocationToken("APPDATA", () => "C:/App/Data")
        };
        var sut = new LocationResolver(tokens);

        // Act
        var result = sut.ResolveLocation("%APPDATA%/settings.json");

        // Assert
        result.Should().Contain("settings.json");
        result.Should().Contain("App");
    }

    [Fact]
    public void ResolveLocation_should_resolve_nested_tokens_recursively_case_insensitive()
    {
        // Arrange
        var tokens = new[]
        {
            new LocationToken("ROOT", () => "C:/Root"),
            new LocationToken("CONFIG", () => "%ROOT%/cfg"),
        };
        var sut = new LocationResolver(tokens);

        // Act
        var result = sut.ResolveLocation("%config%/file.txt");

        // Assert
        result.Should().Contain("Root");
        result.Should().EndWith("cfg" + System.IO.Path.DirectorySeparatorChar + "file.txt");
    }
}
```

This example aligns with the requested structure and libraries in the current solution’s test projects.

---

### Running tests

- Via Rider/Visual Studio Test Explorer: run/cover per project, class, or method.
- Via CLI at the solution root:

```powershell
dotnet test
```

To run a specific project:

```powershell
dotnet test .\tests\Storage\Storage.File.Tests\Ploch.Tools.SystemProfiles.Storage.File.Tests.csproj
```

---

### Review checklist for new tests

- Project/Namespace mirrors the product module under test.
- Class named `<SubjectName>Tests` and `[TestSubject(typeof(...))]` used when applicable.
- Use xUnit v3 attributes and FluentAssertions.
- Prefer `[Theory]` with data when checking multiple cases.
- Use `AutoMockData` when SUT has dependencies.
- Assertions are clear and test only one behavior per test.
- No reliance on global state or time unless explicitly controlled.
