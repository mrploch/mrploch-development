using System.ComponentModel.DataAnnotations;
using Ploch.Data.Model;

namespace Ploch.App.Model;

public class ArticleProperty : IHasId<int>, INamed, IHasValue<string>
{
    [Key]
    public int Id { get; set; }

    [Required]
    [MaxLength(128)]
    public string Name { get; set; } = null!;

    [Required]
    public string Value { get; set; } = null!;

    public int ArticleId { get; set; }

    public virtual Article Article { get; set; } = null!;
}
