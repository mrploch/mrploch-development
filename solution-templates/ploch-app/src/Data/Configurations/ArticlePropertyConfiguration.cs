using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using Ploch.App.Model;

namespace Ploch.App.Data.Configurations;

/// <summary>
/// <see cref="ArticleProperty"/> entity configuration.
/// The Article-ArticleProperty relationship (required foreign key, cascade delete) is configured
/// from the Article side in <see cref="ArticleConfiguration"/>; the remaining constraints come from
/// the data annotations on <see cref="ArticleProperty"/>.
/// </summary>
internal sealed class ArticlePropertyConfiguration : IEntityTypeConfiguration<ArticleProperty>
{
    public void Configure(EntityTypeBuilder<ArticleProperty> builder)
    {
        // Intentionally empty — see the type summary.
    }
}
