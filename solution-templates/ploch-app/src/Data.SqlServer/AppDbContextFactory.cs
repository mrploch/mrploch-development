using Ploch.App.Data;
using Ploch.Data.EFCore;
using Ploch.Data.EFCore.SqlServer;

namespace Ploch.App.Data.SqlServer;

/// <summary>
/// Design-time factory for <see cref="AppDbContext"/> backed by SQL Server.
/// Used by the EF Core tools (<c>dotnet ef migrations add</c> / <c>database update</c>)
/// and by the helper scripts in this folder.
/// </summary>
public class AppDbContextFactory()
    : SqlServerDbContextFactory<AppDbContext, AppDbContextFactory>(
        static options => new(options, new DefaultDbContextCreationLifecycle()))
{
}
