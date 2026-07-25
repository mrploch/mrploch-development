using System.Globalization;
using Microsoft.EntityFrameworkCore;
using Ploch.App.Data;
using Ploch.App.Model;
using Ploch.Data.GenericRepository;
using Spectre.Console;
using Spectre.Console.Cli;

namespace Ploch.App.ConsoleApp.Commands;

/// <summary>
/// Demonstrates a basic create/read flow through the Ploch.Data generic repository
/// and Unit of Work, rendering the result as a Spectre.Console table.
/// </summary>
internal sealed class DemoCommand(AppDbContext dbContext, IUnitOfWork unitOfWork) : AsyncCommand
{
    public override async Task<int> ExecuteAsync(CommandContext context, CancellationToken cancellationToken)
    {
        // This demo uses a throwaway database (demo.db, see appsettings.json) and recreates it on
        // every run via EnsureDeleted + EnsureCreated, so it runs with zero setup and never collides
        // with the migration-managed database under src/Data.SQLite / src/Data.SqlServer. For a real
        // app, remove this block and apply migrations instead (`dbContext.Database.MigrateAsync()`).
        await dbContext.Database.EnsureDeletedAsync(cancellationToken);
        await dbContext.Database.EnsureCreatedAsync(cancellationToken);

        var authorRepository = unitOfWork.Repository<Author, int>();
        var author = new Author { Name = "Jane Smith", Description = "Technical writer and software engineer" };
        await authorRepository.AddAsync(author, cancellationToken);

        var articleRepository = unitOfWork.Repository<Article, int>();
        await articleRepository.AddAsync(new Article { Title = "Getting Started with the Generic Repository", Author = author }, cancellationToken);
        await articleRepository.AddAsync(new Article { Title = "Advanced Repository Patterns", Author = author }, cancellationToken);
        await unitOfWork.CommitAsync(cancellationToken);

        var articles = await articleRepository.GetAllAsync(
            onDbSet: query => query.Include(article => article.Author),
            cancellationToken: cancellationToken);

        var table = new Table().AddColumns("Id", "Title", "Author", "Created (UTC)");
        foreach (var article in articles)
        {
            table.AddRow(
                article.Id.ToString(CultureInfo.InvariantCulture),
                Markup.Escape(article.Title),
                Markup.Escape(article.Author?.Name ?? "-"),
                article.CreatedTime?.ToString("u", CultureInfo.InvariantCulture) ?? "-");
        }

        AnsiConsole.MarkupLine("[bold green]Ploch.App[/] — generic repository demo");
        AnsiConsole.Write(table);
        return 0;
    }
}
