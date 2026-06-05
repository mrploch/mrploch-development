using Ploch.App.Data;
using Ploch.App.Model;
using Ploch.Data.GenericRepository.EFCore.IntegrationTesting;

namespace Ploch.App.IntegrationTests;

public class UnitOfWorkTests : GenericRepositoryDataIntegrationTest<AppDbContext>
{
    [Fact]
    public async Task CommitAsync_should_persist_changes_across_multiple_repositories()
    {
        var unitOfWork = CreateUnitOfWork();

        var authorRepository = unitOfWork.Repository<Author, int>();
        var articleRepository = unitOfWork.Repository<Article, int>();

        var author = new Author { Name = "Test Author" };
        await authorRepository.AddAsync(author);

        var article = new Article { Title = "Test Article", Author = author };
        await articleRepository.AddAsync(article);

        await unitOfWork.CommitAsync();

        var savedAuthor = await authorRepository.GetByIdAsync(author.Id);
        var savedArticle = await articleRepository.GetByIdAsync(article.Id);

        savedAuthor.Should().NotBeNull();
        savedArticle.Should().NotBeNull();
        savedArticle!.AuthorId.Should().Be(savedAuthor!.Id);
    }

    [Fact]
    public async Task CommitAsync_should_update_audit_modified_time_on_update()
    {
        var unitOfWork = CreateUnitOfWork();
        var articleRepository = unitOfWork.Repository<Article, int>();

        var article = new Article { Title = "Original Title" };
        await articleRepository.AddAsync(article);
        await unitOfWork.CommitAsync();

        var createdTime = article.CreatedTime;
        createdTime.Should().NotBeNull();

        await Task.Delay(50);

        article.Title = "Updated Title";
        await articleRepository.UpdateAsync(article);
        await unitOfWork.CommitAsync();

        article.ModifiedTime.Should().NotBeNull();
        article.ModifiedTime.Should().BeAfter(createdTime!.Value);
    }

    [Fact]
    public async Task DeleteAsync_should_remove_entity()
    {
        var unitOfWork = CreateUnitOfWork();
        var tagRepository = unitOfWork.Repository<ArticleTag, int>();

        var tag = new ArticleTag { Name = "Temporary Tag" };
        await tagRepository.AddAsync(tag);
        await unitOfWork.CommitAsync();

        var tagId = tag.Id;

        await tagRepository.DeleteAsync(tag);
        await unitOfWork.CommitAsync();

        var deleted = await tagRepository.GetByIdAsync(tagId);
        deleted.Should().BeNull();
    }
}
