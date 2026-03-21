# Demo Recording

## Option A: vhs (recommended)

```bash
brew install charmbracelet/tap/vhs
vhs demo/demo.tape
```

Generates `demo/demo.gif`. Edit `demo.tape` to customize.

## Option B: asciinema

```bash
brew install asciinema
asciinema rec demo/demo.cast
# Run the commands manually, then ctrl+d to stop
# Convert to GIF:
npm install -g svg-term-cli
svg-term --in demo/demo.cast --out demo/demo.svg --window
```

## Option C: Manual screen recording

1. Open terminal, resize to ~900x500
2. Run these commands:
   ```
   cd ~/my-project
   claude
   /forge init
   /forge audit
   /forge status
   ```
3. Trim to ~30 seconds
4. Export as GIF (ezgif.com or gifski)

## After recording

Add to README.md after the badges:
```markdown
![claude-kit demo](demo/demo.gif)
```
