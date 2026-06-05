using Microsoft.EntityFrameworkCore;
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

        var authorRepo = unitOfWork.Repository<Author, int>();
        var articleRepo = unitOfWork.Repository<Article, int>();

        var author = new Author { Name = "Test Author" };
        await authorRepo.AddAsync(author);

        var article = new Article { Title = "Test Article", Author = author };
        await articleRepo.AddAsync(article);

        await unitOfWork.CommitAsync();

        // Verify both rows landed in the database via a fresh root DbContext, not the writer's context.
        await using var verifyContext = CreateRootDbContext();
        var savedAuthor = await verifyContext.Authors.FindAsync(author.Id);
        var savedArticle = await verifyContext.Articles.FindAsync(article.Id);

        savedAuthor.Should().NotBeNull();
        savedArticle.Should().NotBeNull();
        savedArticle!.AuthorId.Should().Be(savedAuthor!.Id);
    }

    [Fact]
    public async Task CommitAsync_should_update_audit_modified_time_on_update()
    {
        var unitOfWork = CreateUnitOfWork();
        var articleRepo = unitOfWork.Repository<Article, int>();

        var article = new Article { Title = "Original Title" };
        await articleRepo.AddAsync(article);
        await unitOfWork.CommitAsync();

        var createdTime = article.CreatedTime;
        createdTime.Should().NotBeNull();

        await Task.Delay(50);

        article.Title = "Updated Title";
        await articleRepo.UpdateAsync(article);
        await unitOfWork.CommitAsync();

        // Confirm the audit timestamp was advanced and persisted by reloading from the database.
        await using var verifyContext = CreateRootDbContext();
        var saved = await verifyContext.Articles.FindAsync(article.Id);

        saved.Should().NotBeNull();
        saved!.Title.Should().Be("Updated Title");
        saved.ModifiedTime.Should().NotBeNull();
        saved.ModifiedTime.Should().BeOnOrAfter(createdTime!.Value);
    }

    [Fact]
    public async Task DeleteAsync_should_remove_entity()
    {
        var unitOfWork = CreateUnitOfWork();
        var tagRepo = unitOfWork.Repository<ArticleTag, int>();

        var tag = new ArticleTag { Name = "Temporary Tag" };
        await tagRepo.AddAsync(tag);
        await unitOfWork.CommitAsync();

        var tagId = tag.Id;

        await tagRepo.DeleteAsync(tag);
        await unitOfWork.CommitAsync();

        // Verify removal via a fresh root DbContext rather than the repository under test.
        await using var verifyContext = CreateRootDbContext();
        var deleted = await verifyContext.ArticleTags.FindAsync(tagId);
        deleted.Should().BeNull();
    }
}
