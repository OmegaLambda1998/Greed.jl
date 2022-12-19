module RunModule

# External Packages
using OrderedCollections
using Random

# Internal Packages
include("DiceModule.jl")
using .DiceModule
include("PlayerModule.jl")
using .PlayerModule
include("GameModule.jl")
using .GameModule
include("GauntletModule.jl")
using .GauntletModule

# Exports
export run_Greed

function get_game(config::Dict, players::Vector{Player}, global_config::Dict)
    rules = parse_rules(config["rules"])
    start_score = config["start_score"]
    end_score = config["end_score"]
    return Game(rules, start_score, end_score, players)
end

function run_Greed(toml::Dict)
    global_config = toml["global"]
    seed = get(toml, "seed", 0000)
    Random.seed!(seed)
    gauntlet = get(toml, "gauntlet", nothing)
    players = get_players(toml["players"], global_config)
    if isnothing(gauntlet)
        @info "Players: $(join([p.name for p in players], ", ", " and "))\n"
        game = get_game(toml["game"], players, global_config)
        run_game(game)
    else
        gauntlet_players = Vector{Vector{Player}}()
        for i in 1:length(players)
            for j in 1:length(players)
                p1 = Player([getfield(players[i], key) for key in fieldnames(Player)]...)
                p1.name *= " 1"
                p2 = Player([getfield(players[j], key) for key in fieldnames(Player)]...)
                p2.name *= " 2"
                push!(gauntlet_players, [p1, p2])
            end
        end
        gauntlet_games = Vector{Game}()
        for p in gauntlet_players
            game = Game(toml["game"], p, global_config)
            push!(gauntlet_games, game)
        end
        order = [p.name for p in players]
        gauntlet = Gauntlet(toml["gauntlet"], gauntlet_games, order, global_config)
        run_gauntlet(gauntlet, global_config)
    end
end

end
