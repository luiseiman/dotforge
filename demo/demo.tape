# claude-kit demo recording
# Install vhs: brew install charmbracelet/tap/vhs
# Run: vhs demo/demo.tape
# Output: demo/demo.gif

Output demo/demo.gif
Set FontSize 16
Set Width 900
Set Height 500
Set Theme "Catppuccin Mocha"
Set TypingSpeed 50ms
Set Padding 20

# Scene 1: Init a project
Type "cd ~/my-fastapi-project"
Enter
Sleep 500ms

Type "claude"
Enter
Sleep 2s

Type "/forge init"
Enter
Sleep 4s

# Expected output:
# ✓ claude-kit initialized — python-fastapi, docker-deploy — score 9.5/10

Sleep 2s

# Scene 2: Audit
Type "/forge audit"
Enter
Sleep 5s

# Expected output: score breakdown

Sleep 3s

# Scene 3: Status
Type "/forge status"
Enter
Sleep 4s

# Expected output: multi-project dashboard

Sleep 3s

# End
Type "exit"
Enter
Sleep 1s
