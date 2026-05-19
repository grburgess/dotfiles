# gptel — Claude auth setup

## Prerequisite

Anthropic enterprise API key (`sk-ant-api03-...`). If your org has key creation disabled in the console, request it from your workspace admin.

## Steps

1. Visit https://console.anthropic.com → API Keys → Create. Save key (`sk-ant-api03-...`).
2. Append to `~/.authinfo.gpg` (encrypted) or `~/.authinfo` (plaintext, less safe):

   ```
   machine api.anthropic.com login apikey password sk-ant-api03-XXXXXXXXXXXXXXXXXXXX
   ```

3. In Emacs: `M-x gptel-send` — first call should now succeed.

## Org-mode usage

Open any `.org` file, write a prompt, `C-c RET` (or `M-x gptel-send`). Response streams into buffer.

## Switching models

`M-x gptel-menu` → change model (claude-opus-4-X / sonnet-4-X / haiku-4-X).
