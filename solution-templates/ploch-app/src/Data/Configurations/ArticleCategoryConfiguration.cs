using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using Ploch.App.Model;

namespace Ploch.App.Data.Configurations;

internal sealed class ArticleCategoryConfiguration : IEntityTypeConfiguration<ArticleCategory>
{
    public void Configure(EntityTypeBuilder<ArticleCategory> builder)
    {
        builder.HasOne(c => c.Parent)
               .WithMany(c => c.Children)
               .IsRequired(false)
               .OnDelete(DeleteBehavior.ClientCascade);
    }
}
