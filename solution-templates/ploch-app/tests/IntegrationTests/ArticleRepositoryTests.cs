using Microsoft.EntityFrameworkCore;
using Ploch.App.Data;
using Ploch.App.Model;
using Ploch.Data.GenericRepository.EFCore.IntegrationTesting;

namespace Ploch.App.IntegrationTests;

public class ArticleRepositoryTests : GenericRepositoryDataIntegrationTest<AppDbContext>
{
    [Fact]
    public async Task AddAsync_should_persist_article_with_audit_properties()
    {
        var repository = CreateReadWriteRepositoryAsync<Article, int>();

        var article = new Article { Title = "Test Article", Description = "A test article", Contents = "Some content" };

        await repository.AddAsync(article);
        await DbContext.SaveChangesAsync();

        var saved = await repository.GetByIdAsync(article.Id);

        saved.Should().NotBeNull();
        saved!.Title.Should().Be("Test Article");
        saved.CreatedTime.Should().NotBeNull();
        saved.ModifiedTime.Should().NotBeNull();
    }

    [Fact]
    public async Task AddAsync_should_persist_article_with_categories_and_tags()
    {
        var articleRepository = CreateReadWriteRepositoryAsync<Article, int>();
        var categoryRepository = CreateReadWriteRepositoryAsync<ArticleCategory, int>();
        var tagRepository = CreateReadWriteRepositoryAsync<ArticleTag, int>();

        var category = new ArticleCategory { Name = "Test Category" };
        await categoryRepository.AddAsync(category);

        var tag = new ArticleTag { Name = "Test Tag", Description = "A test tag" };
        await tagRepository.AddAsync(tag);

        var article = new Article
        {
            Title = "Test Article",
            Categories = new List<ArticleCategory> { category },
            Tags = new List<ArticleTag> { tag },
        };

        await articleRepository.AddAsync(article);
        await DbContext.SaveChangesAsync();

        var saved = await articleRepository.GetByIdAsync(
            article.Id,
            onDbSet: query => query.Include(a => a.Categories).Include(a => a.Tags));

        saved.Should().NotBeNull();
        saved!.Categories.Should().HaveCount(1);
        saved.Categories!.First().Name.Should().Be("Test Category");
        saved.Tags.Should().HaveCount(1);
        saved.Tags.First().Name.Should().Be("Test Tag");
    }

    [Fact]
    public async Task AddAsync_should_persist_hierarchical_categories()
    {
        var categoryRepository = CreateReadWriteRepositoryAsync<ArticleCategory, int>();

        var grandchild = new ArticleCategory { Name = "Grandchild" };
        var child = new ArticleCategory { Name = "Child", Children = new List<ArticleCategory> { grandchild } };
        var parent = new ArticleCategory { Name = "Parent", Children = new List<ArticleCategory> { child } };

        await categoryRepository.AddAsync(parent);
        await DbContext.SaveChangesAsync();

        var savedParent = await categoryRepository.GetByIdAsync(
            parent.Id,
            onDbSet: query => query.Include(c => c.Children!).ThenInclude(c => c.Children!));

        savedParent.Should().NotBeNull();
        savedParent!.Children.Should().HaveCount(1);
        savedParent.Children!.First().Name.Should().Be("Child");
        savedParent.Children!.First().Children.Should().HaveCount(1);
        savedParent.Children!.First().Children!.First().Name.Should().Be("Grandchild");
    }

    [Fact]
    public async Task GetPageAsync_should_return_paginated_results()
    {
        var repository = CreateReadWriteRepositoryAsync<Article, int>();

        for (var i = 0; i < 10; i++)
        {
            await repository.AddAsync(new Article { Title = $"Article {i + 1}" });
        }

        await DbContext.SaveChangesAsync();

        var page = await repository.GetPageAsync(1, 5);

        page.Should().HaveCount(5);
    }

    [Fact]
    public async Task GetAllAsync_with_filter_should_return_matching_results()
    {
        var repository = CreateReadWriteRepositoryAsync<Article, int>();

        await repository.AddAsync(new Article { Title = "C# Tutorial" });
        await repository.AddAsync(new Article { Title = "Java Guide" });
        await repository.AddAsync(new Article { Title = "C# Advanced" });
        await DbContext.SaveChangesAsync();

        var csharpArticles = await repository.GetAllAsync(onDbSet: query => query.Where(a => a.Title.Contains("C#")));

        csharpArticles.Should().HaveCount(2);
        csharpArticles.Should().OnlyContain(a => a.Title.Contains("C#"));
    }
}
