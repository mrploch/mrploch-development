using Ploch.Data.Model.CommonTypes;

namespace Ploch.App.Model;

public class ArticleCategory : Category<ArticleCategory>
{
    public virtual ICollection<Article> Articles { get; set; } = new List<Article>();
}
