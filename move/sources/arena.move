module challenge::arena;

use challenge::hero::Hero;
use sui::event;

// ========= STRUCTS =========

public struct Arena has key, store {
    id: UID,
    warrior: Hero,
    owner: address,
}

// ========= EVENTS =========

public struct ArenaCreated has copy, drop {
    arena_id: ID,
    timestamp: u64,
}

public struct ArenaCompleted has copy, drop {
    winner_hero_id: ID,
    loser_hero_id: ID,
    timestamp: u64,
}

// ========= FUNCTIONS =========

public fun create_arena(hero: Hero, ctx: &mut TxContext) {

    // Create an arena object
    let arena = Arena {
        id: object::new(ctx),
        warrior: hero,
        owner: ctx.sender(),
    };
    
    // Emit ArenaCreated event with arena ID and timestamp
    event::emit(ArenaCreated {
        arena_id: object::id(&arena),
        timestamp: ctx.epoch_timestamp_ms(),
    });
    
    // Use transfer::share_object() to make it publicly tradeable
    transfer::share_object(arena);
}

#[allow(lint(self_transfer))]
public fun battle(hero: Hero, arena: Arena, ctx: &mut TxContext) {
    
    // Implement battle logic
    let Arena { id, warrior, owner } = arena;
    
    // Compare hero.hero_power() with warrior.hero_power()
    if (challenge::hero::hero_power(&hero) > challenge::hero::hero_power(&warrior)) {
        // If hero wins: both heroes go to ctx.sender()
        transfer::transfer(hero, ctx.sender());
        transfer::transfer(warrior, ctx.sender());
        
        // Emit BattlePlaceCompleted event with winner/loser IDs
        event::emit(ArenaCompleted {
            winner_hero_id: challenge::hero::hero_id(&hero),
            loser_hero_id: challenge::hero::hero_id(&warrior),
            timestamp: ctx.epoch_timestamp_ms(),
        });
    } else {
        // If warrior wins: both heroes go to battle place owner
        transfer::transfer(hero, owner);
        transfer::transfer(warrior, owner);
        
        // Emit BattlePlaceCompleted event with winner/loser IDs
        event::emit(ArenaCompleted {
            winner_hero_id: challenge::hero::hero_id(&warrior),
            loser_hero_id: challenge::hero::hero_id(&hero),
            timestamp: ctx.epoch_timestamp_ms(),
        });
    };
    
    // Delete the battle place ID
    object::delete(id);
}

