// This is the heart of the game.
// It stores the entire state of the program and dictates the order in which various gameplay systems run at a high level
package game

import "core:fmt"
import "core:time"
import "core:math"
import "core:math/rand"
import "core:math/linalg"
import "core:prof/spall"
import "core:strings"
import rl "vendor:raylib"

// This is the entire state of the game
// Each field is its own struct, and stores the state of some 
Game :: struct {
    player          : Player,       // Player position, velocity, health etc.
    tutorial        : Tutorial,     // Initializes tutorial and manages its state
    leveling        : Leveling,     // Player xp, level and other state related to leveling up.
    weapon          : Weapon,       // Fire rate, spread, kick etc.
    enemies         : Enemies,      // Pool of enemies, each with health, velocity etc.
    waves           : Waves,        // Manages when waves of enemies are spawned, and how many.
    pickups         : Pickups,      // Pool of pickups dropped by enemies.
    audio           : Audio,        // Loaded sounds/music available to be played.
    stars           : Stars,        // Stars and their colors. Drawn to the screen as pixels.
    projectiles     : Projectiles,  // Pool of projectiles fired by the player.
    
    game_time       : f64,              // The time used for gameplay.
    request_restart : bool,             // Anything can set this to true and the game will be restarted at the end of the current frame.
    
    pixel_particles : ParticleSystem,   // Pool of particles, which will be drawn to the screen as pixels.
    line_particles  : ParticleSystem,   // Another pool of particles, which will be drawn to the screen as lines.

    on_calc_time_scale : ActionStack(f32, Game),

    render_target_a : rl.RenderTexture2D,   // The texture the game is rendered to.
    render_target_b : rl.RenderTexture2D,   // The texture the game is rendered to.
    shaders         : map[string]rl.Shader, // Named shaders
}

// Kicks off initialization of the various game systems (where needed, not all systems manage their own state)
load_game :: proc(using game : ^Game) {
    render_target_a = rl.LoadRenderTexture(rl.GetScreenWidth(), rl.GetScreenHeight())
    render_target_b = rl.LoadRenderTexture(rl.GetScreenWidth(), rl.GetScreenHeight())

    request_restart = false
    game_time = 0

    shaders = {
        "CRT"       = rl.LoadShader(vsFileName = nil, fsFileName = "res/shaders/crt.fs"),
        "Vignette"  = rl.LoadShader(vsFileName = nil, fsFileName = "res/shaders/vignette.fs"),
    }

    init_action_stack(&on_calc_time_scale)

    init_player(&player)
    init_tutorial(&tutorial)
    init_leveling(&leveling)
    init_weapon(&weapon)
    init_enemies(&enemies)
    init_waves(&waves)
    init_projectiles(&projectiles)
    init_pickups(&pickups)
    init_stars(&stars)
    load_audio(&audio)

    rl.GuiEnableTooltip()

    start_tutorial(game)
}

// Releases resources used by the various game systems (where needed, not all systems manage their own state)
unload_game :: proc(using game : ^Game) {
    rl.UnloadRenderTexture(render_target_a)
    rl.UnloadRenderTexture(render_target_b)
    
    for _, shader in shaders do rl.UnloadShader(shader)

    unload_action_stack(&on_calc_time_scale)

    unload_player(&player)
    unload_weapon(&weapon)
    unload_enemies(&enemies)
    unload_waves(&waves)
    unload_pickups(&pickups)
    unload_audio(&audio)
    unload_mods()
}

// Ticks the various game systems
tick_game :: proc(using game : ^Game) {
    time_scale : f32 = 1
    execute_action_stack(on_calc_time_scale, &time_scale, game)
    dt := rl.GetFrameTime() * time_scale;

    tick_audio(&audio)
    request_restart = rl.IsKeyPressed(.R)

    if !tutorial.complete {
        tick_tutorial(game)
    }

    if !leveling.leveling_up {
        // Tick all the things!
        tick_pickups(game, dt)
        tick_leveling(game)
        tick_player(game, dt)
        tick_player_weapon(game)
        if player.alive && tutorial.complete do tick_waves(game, dt)
        tick_enemies(&enemies, player, dt)
        tick_player_enemy_collision(game, dt)
        tick_projectiles(&projectiles, enemies, dt)
        tick_projectiles_screen_collision(&projectiles)
        tick_projectiles_enemy_collision(&projectiles, &enemies, &pixel_particles, &audio)
        tick_killed_enemies(&enemies, &pickups, &line_particles)
        tick_particles(&pixel_particles, dt)
        tick_particles(&line_particles, dt)    

        game_time += f64(dt)
    }
}

// Draws the various parts of the game
draw_game :: proc(using game : ^Game) {
    // Render game
    {
        rl.BeginTextureMode(render_target_a)
        defer rl.EndTextureMode()
        
        rl.ClearBackground({2, 3, 8, 255})

        draw_stars(&stars)

        draw_player(game)
        draw_enemies(&enemies)
        draw_projectiles(&projectiles)
        draw_pickups(&pickups)
        draw_player_weapon(game)
        draw_particles_as_pixels(&pixel_particles)
        draw_particles_as_lines(&line_particles)

        if !tutorial.complete {
            draw_tutorial(game)
        }
        else {
            draw_game_gui(game)
            draw_waves_gui(&waves, game_time)
        }

        if !player.alive {
            label := strings.clone_to_cstring(
                fmt.tprintf(
                    "GAME OVER\n\nWave: %i\nLevel: %i\nEnemies Killed: %i\n\n",
                    waves.wave_idx,
                    leveling.lvl,
                    enemies.kill_count,
                ), 
                context.temp_allocator,
            )
            font_size : i32 = 20
            rect := centered_label_rect(screen_rect(), label, font_size)

            rl.DrawText(label, i32(rect.x), i32(rect.y + rect.height / 2 - f32(font_size) / 2), font_size, rl.RED)
        }

        rl.DrawFPS(10, 10)
    }

    // Display game
    {
        rl.BeginTextureMode(render_target_b)
        rl.ClearBackground(rl.BLACK)
        rl.BeginShaderMode(shaders["CRT"])
        rl.DrawTextureRec(render_target_a.texture, rl.Rectangle{ 0, 0, f32(render_target_a.texture.width), -f32(render_target_a.texture.height) }, rl.Vector2{ 0, 0 }, rl.WHITE);
        rl.EndShaderMode()
        rl.EndTextureMode()

        swap_render_targets(game)
        
        rl.BeginTextureMode(render_target_b)
        rl.ClearBackground(rl.BLACK)
        rl.BeginShaderMode(shaders["Vignette"])
        rl.DrawTextureRec(render_target_a.texture, rl.Rectangle{ 0, 0, f32(render_target_a.texture.width), -f32(render_target_a.texture.height) }, rl.Vector2{ 0, 0 }, rl.WHITE);
        rl.EndShaderMode()
        rl.EndTextureMode()

        swap_render_targets(game)

        rl.BeginDrawing()
        defer rl.EndDrawing()
        
        rl.DrawTextureRec(render_target_a.texture, rl.Rectangle{ 0, 0, f32(render_target_a.texture.width), -f32(render_target_a.texture.height) }, rl.Vector2{ 0, 0 }, rl.WHITE);

        if leveling.leveling_up {
            draw_level_up_gui(game)
        }
    }
}

swap_render_targets :: proc(game : ^Game) {
    tmp := game.render_target_a
    game.render_target_a = game.render_target_b;
    game.render_target_b = tmp
}