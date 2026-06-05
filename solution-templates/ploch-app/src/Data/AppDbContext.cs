using Microsoft.EntityFrameworkCore;
using Ploch.App.Model;
using Ploch.Data.EFCore;
using Ploch.Data.Model;

namespace Ploch.App.Data;

public class AppDbContext : DbContext
{
    private readonly IDbContextCreationLifecycle _modelCreationLifecycle;

    public AppDbContext(DbContextOptions<AppDbContext> options, IDbContextCreationLifecycle modelCreationLifecycle)
        : base(options) =>
        _modelCreationLifecycle = modelCreationLifecycle;

    protected AppDbContext(IDbContextCreationLifecycle modelCreationLifecycle) =>
        _modelCreationLifecycle = modelCreationLifecycle;

    public DbSet<Article> Articles { get; set; } = null!;

    public DbSet<ArticleCategory> ArticleCategories { get; set; } = null!;

    public DbSet<ArticleTag> ArticleTags { get; set; } = null!;

    public DbSet<ArticleProperty> ArticleProperties { get; set; } = null!;

    public DbSet<Author> Authors { get; set; } = null!;

    public override int SaveChanges()
    {
        SetAuditTimestamps();
        return base.SaveChanges();
    }

    public override Task<int> SaveChangesAsync(CancellationToken cancellationToken = default)
    {
        SetAuditTimestamps();
        return base.SaveChangesAsync(cancellationToken);
    }

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.ApplyConfigurationsFromAssembly(typeof(AppDbContext).Assembly);
        _modelCreationLifecycle.OnModelCreating(modelBuilder, Database);
        base.OnModelCreating(modelBuilder);
    }

    protected override void OnConfiguring(DbContextOptionsBuilder optionsBuilder)
    {
        base.OnConfiguring(optionsBuilder);
        _modelCreationLifecycle.OnConfiguring(optionsBuilder);
    }

    private void SetAuditTimestamps()
    {
        var now = DateTimeOffset.UtcNow;
        foreach (var entry in ChangeTracker.Entries<IHasAuditTimeProperties>()
                     .Where(e => e.State is EntityState.Added or EntityState.Modified))
        {
            switch (entry.State)
            {
                case EntityState.Added:
                    entry.Entity.CreatedTime = now;
                    entry.Entity.ModifiedTime = now;
                    break;
                case EntityState.Modified:
                    entry.Entity.ModifiedTime = now;
                    break;
            }
        }
    }
}
