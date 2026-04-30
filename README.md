# ⚡ Claude Code — One-Click Local Setup

> Run **Claude Code** on your own machine using any **Ollama model** — no API key, no cloud, no fuss.

---

## ✨ Features

- **Zero manual setup** — installs everything it needs automatically (Node.js, Claude Code, Ollama)
- **Your choice of model** — works with any Ollama-compatible model: `qwen2.5:7b`, `llama3:8b`, `phi3`, and more

---

## 🚀 How to Run

1. Go to the [**Releases**](../../releases) page of this repository
2. Download the latest `.zip` file and extract the contents to a **trusted folder** (e.g. your Documents or Desktop — avoid running from Downloads or temp locations)
3. **Double-click `claude.bat`**
4. When prompted, type your Ollama model name (e.g. `qwen2.5:7b`) and press Enter
5. The script handles everything automatically

Once setup is complete, open a terminal in any trusted folder and run:

```
ollama launch claude
```

When asked to select a model, choose the one ending in `-64k` (e.g. `qwen2.5-7b-64k`).

> ⚠️ **Choose a model your PC can handle.** Larger models (13B+) require significantly more RAM and a capable GPU. If you're unsure, start with a smaller model like `qwen2.5:7b` or `phi3` and work your way up.

> **Note:** You may see a SmartScreen security warning since the script is unsigned.  
> Click **"More info" → "Run anyway"** to proceed.

---

## 🛠️ Manual Setup (Step-by-Step)

If you prefer to set things up yourself without running any scripts, follow these steps in order.

### Step 1 — Install Node.js

Go to [nodejs.org](https://nodejs.org), download the **LTS version** for your operating system, and run the installer.

Verify it worked by opening a terminal and running:
```
node --version
```

---

### Step 2 — Install Claude Code

Open a terminal and run:
```
npm install -g @anthropic-ai/claude-code
```

Verify the install:
```
claude --version
```

---

### Step 3 — Install Ollama

Go to [ollama.com](https://ollama.com), download the installer for your operating system, and follow the on-screen steps.

Verify it's installed:
```
ollama --version
```

---

### Step 4 — Start the Ollama Service

Ollama needs to be running as a local API server in the background.

```
ollama serve
```

You can verify it's running by visiting [http://localhost:11434](http://localhost:11434) in your browser — you should see a response.

---

### Step 5 — Pull Your Model

Download the model you want to use. For example:

```
ollama pull qwen2.5:7b
```

Other popular options:
```
ollama pull llama3:8b
ollama pull phi3
```

---

### Step 6 — Create a 64K Context Optimized Model

By default most models use a small context window. This step expands it to 64K so Claude Code can handle larger codebases.

Create a file called `Modelfile` (no extension) with the following content, replacing the model name with whichever model you pulled in Step 5:

```
FROM qwen2.5:7b
PARAMETER num_ctx 65536
```

Then build the optimized model:

```
ollama create qwen2.5-7b-64k -f Modelfile
```

The naming format is `<your-model-name>-64k`. Use this same name when selecting the model at launch.

> **Note:** If your model name contains a colon (e.g. `qwen2.5:7b`), replace it with a hyphen when naming the optimized model — colons are not valid in model names or file paths. So `qwen2.5:7b` becomes `qwen2.5-7b-64k`.

---

### Step 7 — Set Environment Variables

Claude Code needs to know to use Ollama instead of Anthropic's servers. Set these two environment variables on your system:

| Variable Name          | Value                    |
|------------------------|--------------------------|
| `ANTHROPIC_BASE_URL`   | `http://localhost:11434` |
| `ANTHROPIC_AUTH_TOKEN` | `ollama`                 |

How to set environment variables differs by OS — search *"how to set environment variables on [your OS]"* if you're unsure.

> **Windows users:** Open PowerShell as Administrator to ensure environment variables are saved correctly.

---

### Step 8 — Launch Claude Code

Open a terminal and run:

```
ollama launch claude
```

When prompted to select a model, choose the one ending in `-64k` (e.g. `qwen2.5-7b-64k`).

> ⚠️ **Choose a model your PC can handle.** Larger models (13B+) require significantly more RAM and a capable GPU. If you're unsure, start with a smaller model like `qwen2.5:7b` or `phi3` and work your way up.

Claude Code will now connect to your local Ollama instance. 🎉

---

## 🤝 Contributing

Pull requests are welcome! If you encounter an issue or have an idea for improvement, feel free to open an issue.

---

## 📄 License

MIT License — free to use, modify, and distribute.
