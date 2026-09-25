# Godot MCP servers — evaluation (2026-09-25)

Question: should game-builder verify games through an existing Godot MCP server instead of (or next
to) its own `gb` CLI + `gb_harness`?

## What exists (web search, 2026-09-25)

| Server | Shape | Notable |
|---|---|---|
| [Coding-Solo/godot-mcp](https://github.com/Coding-Solo/godot-mcp) | launches the editor, runs projects, captures debug output | closest to `gb run`; no deterministic input or state checks |
| [slangwald/godot-mcp](https://github.com/slangwald/godot-mcp) | Python MCP server ↔ editor plugin (TCP 9500) ↔ game autoload (TCP 9501) | screenshots, input simulation, live scene tree; targets Godot 4.6 |
| [signalcompose/godot-mcp](https://github.com/signalcompose/godot-mcp), [ee0pdt/Godot-MCP](https://github.com/ee0pdt/Godot-MCP), [alexmeckes/godot-mcp](https://github.com/alexmeckes/godot-mcp), [Dokujaa/Godot-MCP](https://github.com/Dokujaa/Godot-MCP) | editor-plugin based | scene/script editing from the agent |
| [youichi-uda/godot-mcp-pro](https://github.com/youichi-uda/godot-mcp-pro) | paid (one-time) | 160+ tools incl. input simulation, runtime analysis, testing |

## Decision

**`gb` stays the verification instrument; an MCP server is optional, for live editor work only.**

| Criterion | `gb` + `gb_harness` | MCP servers |
|---|---|---|
| Deterministic, repeatable verdict | yes — fixed physics frames, seeded RNG, replay with state match (tested) | live, time-based interaction; no replay/state contract |
| Runs in CI / on a fresh clone | yes (headless CLI, Linux build in `verify.yml`) | needs a running editor/game and open ports |
| Covered by this repo's tests | yes (`npm test`, real engine) | would be third-party code we cannot pin-test the same way |
| Attack surface | none (no listening sockets) | TCP ports on localhost, third-party plugin code in the game |
| Version pinning | follows the project's Godot version | several target a specific minor (e.g. 4.6) |
| Live scene editing in the editor | no (agents edit .tscn/.gd files) | yes — the real strength |

When an MCP server helps: interactive level building in an open editor, or exploring a running game
by hand with the agent. If the human wants one, evaluate a specific server against the project's Godot
version first, keep it out of the exported build, and never let its result replace `gb verify` as
evidence of done.

Not re-evaluated automatically; revisit when a server offers deterministic replay + a CLI mode.
