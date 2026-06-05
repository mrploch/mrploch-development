using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using Ploch.App.Model;

namespace Ploch.App.Data.Configurations;

internal sealed class AuthorConfiguration : IEntityTypeConfiguration<Author>
{
    public void Configure(EntityTypeBuilder<Author> builder)
    {
        // The Author-Article relationship is configured from the Article side in ArticleConfiguration.
        // Basic constraints (Name length / required) are expressed via data annotations on the entity.
    }
}
