# Asterboids
A very simple space-shooter with rogue-like elements. Loosely inspired by the classic arcade game, Asteroids. The game was meant to be a week-long project, with the goal of learning the [Odin](https://odin-lang.org/) language and data-oriented-programming.
I ended up spending a bit more time on it because I was learning a lot and having so much fun!

---

## The Unity "Bubble"

I have been a Unity developer for a bit, and as such I've grown accustomed to OOP and high(ish)-level programming. However over the last couple years I've started feel a bit jaded towards most of the code I read and write.
It's not like I've been ignorant to other paradigms like data-oriented programming - I've seen many of the well-known [talks](https://youtu.be/rX0ItVEVjHc) and [video essays](https://youtu.be/QM1iUe6IofM?list=PLrWlVANGG-ij06UCpfdxQ-LBclsWUDLt-) that make a case against object-oriented programming.
They were quite compelling to me, but I didn't feel like I could employ DOP in a meaningful way in Unity without going against the grain.
This frustration with Unity and OOP in conjunction with a blossoming interest in data-oriented programming led me to Odin!

Now I must admit - I was afraid I would bounce off the language. However, to my surprise the exact opposite occured! Unlike my previous forays into other languages like C++ and Rust, I got completely hooked by Odin.

The following breakdown will be composed of two different parts: an overview of my processes learning Odin as a Unity developer, and a breakdown of the project itself.



## Project Breakdown

Asterboids is a top-down space shooter where the player fights off waves of enemies from their spaceship. The enemies move in bird-like flocks, hence the name Aster*boids*.
Enemies drop orbs which can be picked up to gain health and xp. When the player levels up they can pick a perk that affects the gameplay in some way, like you'd find in a rogue-like.

This project might not be a shining example of how to program in Odin, but I was still really happy with how straightfoward its development felt. It's a simple game, and so is the codebase!
With that in mind, this might be a good resource for other newbies who are looking into Odin and want to poke around a mostly complete project.

When working on the game, there were three things I thought were particularly satisfying to develop: the smoke trails, enemy flocking simulation and rogue-like "modifier" architecture.

### Smoke Trails
TODO: like Control

### Flocking Simulation
TODO: n^2 to hash grid to job system

### Rogue-like System
TODO: more pickups = more projectiles = more pickups



## Learning Odin
### First Steps

I have never properly used a low-level language. So in my eyes, the fact that within an hour of downloading Odin - a language I'd never used - I was drawing graphics to a window is a testament to Odin's accessibility. 
You can start writing code that actually does something cool in less than a day, and feel quite comfortable with the language in less than a week.

Now I'm not going to claim that I immediately understood everything about Odin. I had my fair share of stumbles (and still do!)
Some of the speedbumps were just due to me not understanding unspoked fundamentals. For instance, I was initially confused as to why Raylib "just worked", when SDL only worked with its DLL added to my project.
That led to me learning about static vs dynamic linking and the convenience of header-only libraries.
There were also a couple hiccups regarding manual memory management - mostly just me allocating stuff unnecessarily on the heap and taking a bit to understand Odin's different array types.
Growing pains, but growing nonetheless!

One thing that left a bit to be desired is tooling. Unity and C# have excellent IDE support: auto-complete, refactoring, and attaching a debugger "just works." 
While the Odin Language Server (ols) is pretty easy to setup and handles the basics, I miss certain things I would consider basic functionality like being able to rename a variable across a project.

All that being said, learning Odin has been quite a positive experience for me. Thanks to its focus on simplicity, Odin provided a buttery smooth entry into the world of low-level data-oriented programming.

### Manual Memory Management

I think a lot of people who have exclusively programmed in garbage collected languages would agree that manual memory management is intimidating. "You're telling me I have to remember to free everything!?"

While you do manage memory manually (try saying that 5 times fast), I found that in practice Odin provides some really helpful facilities which leave you with the advantages of manual memory management without much of the headache.

The `defer` keyword allows you to put the code that cleans something up right next to the code that initializes it. I love this because with it you can see at a glance that you've done your housekeeping correctly

Odin's allocators are also really helpful, even for someone like me who hasn't gone very deep into optimizing memory usage. Often times you have some ephemeral data you want to allocate that doesn't need to last for more than a frame.
Rather tham cleaning them up individually, I just used the builtin `context.temp_allocator` and called `free_all(context.temp_allocator)` at the end of each frame to free all my little allocations in one go. Easy peasy!

There was one moment in particular that I thought was pretty magical. I was testing how my game handled being restarted, and noticed that the memory usage kept increasing in Task Manager. I started looking through my code to find a leak, but couldn't track it down for the life of me!
Eventually, out of desperation, I opened the Odin language overview and hit Ctrl+F to see if "leak" was mentioned anywhere. It took me straight to a 20-line example snippet that sets up a "tracking" allocator. I pasted it at the top of my program, ran my game, and it printed the line numbers of
two different places where I allocated memory that was never freed. My mind was blown!

When I first started getting into Odin, I was really steeling myself for a world of hurt as I acclimated to the process of manual memory management. I'm happy to report it really wasn't an issue. I'm sure there's plenty of places where what I'm doing is sub-optimal, but that's bound to happen.
The `defer` keyword and temp/tracking allocators really helped cushion the transition away from GC and I found I quite preferred managing memory explicitly as opposed to the weird meta-game I'm used to playing to appease the garbage collector.

### Data Oriented Programming

Unity was the vessel through which I originally learned programming. It's a very object-oriented ecosystem so I've been a very object-oriented programmer. My noggin has been trained to break down problems in a very abstract way. 
Until recently I couldn't really imagine how I would architect programs any differently. While I could see the sense in other's criticisms of OOP, I still didn't have a concrete understanding of what a data oriented program would look like.

Making a tiny game with Odin forced me to discard what I had felt were the most basic "primitives" of a program architecture. When I finally started solving problems and implementing features without all the object-oriented bells and whistles I was accustomed to, it quickly became clear to me that I had been making mountains out of molehills. 
I was pretty amazed at how everything just...kept staying simple? I know I'm a bit late to the DOP (data-oriented party), but man what a breath of fresh air. I'd be lying if I said I didn't feel a bit of catharsis!
