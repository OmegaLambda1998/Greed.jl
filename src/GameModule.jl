module GameModule

# External Packages
using OrderedCollections

# Internal Packages
using ..PlayerModule

# Exports
export Game
export run_game

mutable struct Game
    rules::OrderedDict{Vector{Int}, Int}
    start_score::Int64
    end_score::Int64
    players::Vector{Player}
end

function victory(game::Game)
    winners = Vector{Player}()
    for player in game.players
        if player.score > game.end_score
            push!(winners, player)
        end
    end
    return winners
end

function run_game(game::Game)
    winners = victory(game)
    if length(winners) > 0
        for player in winners
            println("$(player.name) has won the game!")
        end
        return winners
    end
    println("No winners yet\n")
    for player in game.players
        println("$(player.name)'s turn\n")
        turn!(player, game.rules, game.start_score)
        println("---------")
    end
    for player in game.players
        println("$(player.name) has $(player.score) points")
        reset!(player)
    end
    println("*********")
    return run_game(game)
end

end
