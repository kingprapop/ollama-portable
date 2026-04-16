![Logo](/ollamaportablelogo.png)

# Welcome to Ollama Portable
**A portable web interface for running local LLMs**

#### What is this?

Ollama Portable combines [Ollama](https://github.com/ollama/ollama), [Hollama](https://github.com/fmaclen/hollama) and [Caddy](https://github.com/caddyserver/caddy) into a single, self-contained package.
Everything runs directly from one folder, no external dependencies or system changes required.

No installation. No setup. No admin rights needed.

---

#### How to use Ollama Portable

**1. Open the web interface**

Once the server is running, open your browser and go to:

```
http://localhost:47474/autosetup.html
```

This will automatically load your saved models and settings.

---

**2. Start chatting**

Click the **New Session** button at the top left of the page to immediately start chatting with the default Gemma 4 model.

---

**3. Add more models**

Click the **Settings** button at the bottom left of the page. In the **Pull Model** field, enter the name of the model you want to download, then click the download button next to it.

Not sure which model to use? Click the **Ollama Library** link to browse all available models.

---

**4. Save your sessions and settings**

Click the **Settings** button at the bottom left of the page, then export your preferences or sessions. Copy the generated JSON file to:

```
[your drive]:\ollama-portable\webui\build\settings
```

Your settings and sessions will be automatically restored the next time you launch Ollama Portable.

---

#### About

Built by the team behind [EKHOS AI](https://ekhos.ai) — Professional-grade Local AI transcription app built for users who prioritize privacy, security, and full data control.