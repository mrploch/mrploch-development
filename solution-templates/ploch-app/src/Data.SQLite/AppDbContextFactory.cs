using Ploch.App.Data;
using Ploch.Data.EFCore.SqLite;

namespace Ploch.App.Data.SQLite;

/// <summary>
/// Design-time factory for <see cref="AppDbContext"/> backed by SQLite.
/// Used by the EF Core tools (<c>dotnet ef migrations add</c> / <c>database update</c>)
/// and by the helper scripts in this folder.
/// </summary>
public class AppDbContextFactory()
    : SqLiteDbContextFactory<AppDbContext, AppDbContextFactory>(static options => new(options, CreationLifecycle))
{
}
