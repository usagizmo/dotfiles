# --------------------
# Private Environment Variables
# init.sh が ~/.config/fish/conf.d/env.fish へ初回 copy する（untracked）
# --------------------

# Google Cloud Platform (Gemini CLI用)
set -gx GOOGLE_CLOUD_PROJECT YOUR_PROJECT_ID_HERE

# Command Code (Provider API / pi用)
set -gx CMD_API_KEY YOUR_CMD_API_KEY_HERE
