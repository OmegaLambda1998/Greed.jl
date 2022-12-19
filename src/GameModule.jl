module GameModule

# External Packages
using OrderedCollections
using Base

# Internal Packages
using ..PlayerModule

# Exports
export Game
export run_game
export parse_rules

mutable struct Game
    rules::OrderedDict{Vector{Int}, Int}
    start_score::Int64
    end_score::Int64
    players::Vector{Player}
end

function Base.deepcopy(game::Game)
    return Game(game.rules, game.start_score, game.end_score, [deepcopy(p) for p in game.players])
end

function Game(config::Dict, players::Vector{Player}, global_config::Dict)
    rules = parse_rules(config["rules"])
    start_score = config["start_score"]
    end_score = config["end_score"]
    return Game(rules, start_score, end_score, players)
end

function parse_rules(rules::Dict)
    parsed = OrderedDict{Vector{Int},Int}()
    for key in sort(collect(keys(rules)), lt = (x, y) -> (length(x) + rules[x]) < (length(y) + rules[y]), rev=true)
        k = parse.(Int, split(key, ""))
        parsed[k] = rules[key]
    end
    return parsed
end

function victory(game::Game)
    winners = OrderedDict{Int64, Player}()
    for (i, player) in enumerate(game.players)
        if player.score > game.end_score
            winners[i] = player
        end
    end
    return winners
end

function run_game(game::Game)
    winners = victory(game)
    if length(winners) > 0
        for i in keys(winners)
            player = winners[i]
            @info "$(player.name) has won the game!"
        end
        for player in game.players
            player.score = 0
            player.scoring = false
            reset!(player)
        end
        return winners
    end
    @info "No winners yet\n"
    for player in game.players
        @info "$(player.name)'s turn\n"
        turn!(player, game.rules, game.start_score)
        @info "---------"
    end
    for player in game.players
        @info "$(player.name) has $(player.score) points"
        reset!(player)
    end
    @info "*********"
    return run_game(game)
end

end
