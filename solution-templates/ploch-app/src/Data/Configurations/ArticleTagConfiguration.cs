using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using Ploch.App.Model;

namespace Ploch.App.Data.Configurations;

/// <summary>
/// <see cref="ArticleTag"/> entity configuration.
/// The Article-ArticleTag many-to-many relationship is configured from the Article side in
/// <see cref="ArticleConfiguration"/>; the remaining constraints come from the base
/// <c>Tag</c> type and data annotations.
/// </summary>
internal sealed class ArticleTagConfiguration : IEntityTypeConfiguration<ArticleTag>
{
    public void Configure(EntityTypeBuilder<ArticleTag> builder)
    {
        // Intentionally empty — see the type summary.
    }
}
