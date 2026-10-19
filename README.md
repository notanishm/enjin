# Enjin

AI-assisted game development for Godot. A natural-language editor assistant
("add a cube", "make the sphere twice as big", "give my player sprint and
double jump") backed by a three-layer pipeline, plus a reusable capability
library and code-snippet corpus.

## How it works

```
your prompt ──▶ LLM planner ──▶ Jev validator ──▶ local executors ──▶ scene
                (intent JSON)   (skill check)     (deterministic GDScript)
```

1. **LLM planner** turns the prompt into registry-grounded task JSON
   (skillset / skill / target / params). Supports GitHub Copilot, OpenAI,
   Anthropic, and OpenRouter.
2. **Jev validator** (one batched API call) confirms or corrects the skill
   choice per task; it wins on disagreement.
3. **Local executors** apply the change to the open scene — hand-written,
   reviewable GDScript only. Models never emit code or touch the scene
   directly. All modify operations are wrapped in the editor undo system
   (Ctrl+Z works).

If the LLM plan is unparseable, a local keyword fallback still handles common
resize/move/rotate/delete prompts with zero network calls.

## Requirements

- **Godot 4.x** (developed and tested against **4.7.2**)
- A **Jev API key** (required — skill validation layer)
- An **LLM provider** (required for most prompts):
  - **GitHub Copilot** — no key needed in the dialog; the token is read
    automatically from opencode's auth store (`~/.local/share/opencode/auth.json`)
  - or **OpenAI / Anthropic / OpenRouter** API key
  - or **Direct (No LLM)** — local keyword commands only (no planning pipeline)

## Install (into your own project)

1. Copy `addons/ai_assistant/` into your project's `addons/` folder:

   ```
   your_project/
     addons/
       ai_assistant/
         ai_panel.gd
         ai_panel.tscn
         plugin.cfg
         plugin.gd
         settings_dialog.gd
         settings_dialog.tscn
         ...
   ```

   (Or clone this repo and copy from there.)

2. In Godot: **Project → Project Settings → Plugins** → enable
   **"AI Game Assistant"**.

3. The assistant dock appears in the editor. Click **Settings**:
   - Paste your **Jev API key**
   - Pick an **LLM provider** and paste its key (skip for GitHub Copilot /
     Direct)
   - Optional: set a **model override** (e.g. `gpt-4o-mini` for lower latency)

4. Type into the dock and press Enter. Try `help` for the command list.

Settings are stored per-project at
`user://ai_assistant_settings.cfg` (outside the repo — keys are never
committed).

## Usage examples

```
add a cube
walkable floor
playable character
give my player sprint and double jump
camera lookaround
make the sphere twice as big
move the cube 2 meters left
put the sphere on the floor
rotate the tree 45 degrees
remove the cube
```

`list` shows what's been built this session; `clear` resets memory.

## Try the demo project

1. Open `demo/` as a project in Godot 4.x (the addon is already installed
   there).
2. Enable the plugin as above and set your keys.
3. Open a scene (or create one) and use the dock.

> `demo/model/` contains a large generated asset that is not in git — the demo
> runs fine without it.

## Repository layout

| Path | Contents |
|---|---|
| `addons/ai_assistant/` | The editor plugin (master copy) |
| `demo/` | Demo Godot project (scenes, scripts, addon copy) |
| `capabilities/` | Capability library: yaml manifests + GDScript implementations + tests |
| `code_snippets/` | Annotated snippet corpus per domain (AI, camera, audio, …) |
| `CORPUS.md` | Corpus notes |

`godot/`, `godot_exe/`, `godot_source/`, `third_party/`, and `.env` are
intentionally gitignored (engine binaries, checkouts, and secrets).

## Notes

- Spawns, resizes, moves, rotations, and deletes are all executed locally and
  are undoable in the editor.
- The assistant remembers characters/skills/objects across prompts until you
  press **Clear**.
- The LLM only ever classifies against a fixed skill registry — it cannot
  invent skills or write scene code. New capabilities require adding an
  executor to the addon.
