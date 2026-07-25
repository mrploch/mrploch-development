using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Ploch.App.ConsoleApp.Commands;
using Ploch.App.Data;
using Ploch.CommandLine.Spectre;
using Ploch.Data.GenericRepository.EFCore.DependencyInjection;
using Spectre.Console.Cli;

var app = AppBuilder.Create(args)
                    .WithName("Ploch.App")
                    .WithVersion(new Version(1, 0, 0))
                    .WithDescription("Ploch.App sample console — demonstrates the Ploch.Data generic repository flow.")

                    // Resolve appsettings.json next to the executable so the app runs from any working directory.
                    .ConfigureHost(host => host.UseContentRoot(AppContext.BaseDirectory))
                    .ConfigureServices(services => services.AddDbContextWithRepositories<AppDbContext>())
                    .ConfigureCommandApp(config => config.AddCommand<DemoCommand>("demo"));

return await app.RunAsync(args);
