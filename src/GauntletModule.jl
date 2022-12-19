module GauntletModule

# External Packages
using OrderedCollections
using ProgressMeter
using CairoMakie
using Logging

# Internal Packages
using ..GameModule

# Exports
export Gauntlet
export run_gauntlet

mutable struct Gauntlet
    games::Vector{Game}
    order::Vector{String}
    num_games::Int64
    results::OrderedDict{Int64, OrderedDict{String, Int64}}
end

function Gauntlet(config::Dict, games::Vector{Game}, order::Vector{String}, global_config::Dict)
    num_games = config["num_games"]
    results = OrderedDict{Int64, OrderedDict{String, Int64}}()
    for i in 1:length(games)
        results[i] = OrderedDict{String, Int64}()
        players = games[i].players
        for p in players
            results[i][p.name] = 0
        end
    end
    return Gauntlet(games, order, num_games, results)
end

function run_gauntlet(gauntlet::Gauntlet, global_config::Dict)
    @info "Running gauntlet with $(length(gauntlet.games)) combatants"
    @info "Running $(gauntlet.num_games) competitions"
    @debug "Deepcopying all games"
    p = Progress(gauntlet.num_games)
    games = Vector{Vector{Game}}()
    for i in 1:gauntlet.num_games
        g = Vector{Game}()
        for game in gauntlet.games
            push!(g, deepcopy(game))
        end
        push!(games, g)
        next!(p)
    end
    @info "Running gauntlet"
    Logging.disable_logging(Logging.Info)
    p = Progress(gauntlet.num_games)
    Threads.@threads for i in 1:gauntlet.num_games
        Threads.@threads for (j, game) in collect(enumerate(games[i]))
            winners = run_game(game)
            for k in keys(winners)
                name = winners[k].name
                gauntlet.results[j][name] += 1
            end
        end
        next!(p)
    end
    plot_gauntlet(gauntlet, global_config["output_path"])
end

function plot_gauntlet(gauntlet::Gauntlet, plot_dir::AbstractString)
    names = vcat([collect(keys(gauntlet.results[k])) for k in keys(gauntlet.results)]...)
    names_1 = collect(Set([name for name in names if name[end] == '1']))
    x_sort = sortperm(names_1, by=x -> findfirst(y -> x[1:end-2] == y, gauntlet.order))
    names_1 = names_1[x_sort]
    names_2 = collect(Set([name for name in names if name[end] == '2']))
    y_sort = sortperm(names_2, by=x -> findfirst(y -> x[1:end-2] == y, gauntlet.order))
    names_2 = names_2[y_sort]
    x = [i for i in 1:length(names_1)]
    y = [i for i in 1:length(names_2)]
    X = vcat([x for i in y]...)
    Y = vcat([[i for j in y] for i in x]...)
    Z = Vector{Float64}()
    for i in 1:length(X)
        n1 = names_1[X[i]]
        n2 = names_2[Y[i]]
        for key in keys(gauntlet.results)
            if (n1 in keys(gauntlet.results[key])) && (n2 in keys(gauntlet.results[key]))
                s1 = gauntlet.results[key][n1]
                s2 = gauntlet.results[key][n2]
                push!(Z, s1 - s2)
            end
        end
    end
    Z ./= gauntlet.num_games
    fig, ax, hm = heatmap(X, Y, Z; colormap=:RdBu, colorrange=(-maximum(Z), maximum(Z)))
    for i in 1:length(X)
        txtcol = abs(Z[i]) < 0.25 ? :black : :white
        text!(ax, "$(Z[i])", position = (X[i], Y[i]), align = (:center, :center), color = txtcol) 
    end
    xticks = [n[1:end-2] for n in names_1]
    yticks = [n[1:end-2] for n in names_2]
    ax.xticks = (x, xticks)
    ax.xticklabelrotation = 45.0
    ax.yticks = (y, yticks)
    Colorbar(fig[:, end+1], hm, label = "x score - y score")
    save(joinpath(plot_dir, "Gauntlet.svg"), fig)
end

end
