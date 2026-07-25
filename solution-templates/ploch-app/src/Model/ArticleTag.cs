using Ploch.Data.Model.CommonTypes;

namespace Ploch.App.Model;

public class ArticleTag : Tag
{
    public virtual ICollection<Article> Articles { get; set; } = new List<Article>();
}
