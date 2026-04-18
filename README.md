<p align="center">
  <img width="144" height="144" alt="ollamaportablelogo" src="https://github.com/user-attachments/assets/d174d3d0-24d0-42f1-a7c8-b103f2ff7aab" />
</p>
<br/>

# Ollama Portable
**a portable web chat interface for running local LLMs**

#### What is this?
Ollama Portable combines [Ollama](https://github.com/ollama/ollama), [Hollama](https://github.com/fmaclen/hollama) and [Caddy](https://github.com/caddyserver/caddy) into a single, self-contained package.
Everything runs directly from one folder, no external dependencies or system changes required.
No installation. No setup. No admin rights needed.

---

**Windows**

Download the zip file on the [releases](https://github.com/ekhos-ai/ollama-portable/releases) page and extract `ollama-portable-windows-amd64.zip` to any drive you've chosen.

To start the Ollama Portable server and open the default chat UI, open CMD or Windows Explorer, then run start.bat
Note: On first launch, it will automatically download Ollama and the default Gemma 4 model.

```bat
start.bat
```

---

**Mac OS**

Download the zip file on the [releases](https://github.com/ekhos-ai/ollama-portable/releases) page and extract `ollama-portable-mac-amd64.zip` to any drive you've chosen.

To start the Ollama Portable server and open the default chat UI, open Terminal then run start.sh
Note: On first launch, it will automatically download Ollama and the default Gemma 4 model.

```sh
chmod +x start.sh
./start.sh
```

---

#### AI Model

Ollama Portable comes with **Gemma4** as the default AI model. You can add or download additional AI models from the settings page later.

---

#### Why use Ollama Portable?
- **Fully portable** – runs entirely from your drive with zero system modifications. All models and data are stored in the same folder.
- **Works in restricted environments** – no admin rights or IT approval required, simply extract the ZIP and launch.
- **USB & external drive ready** – carry your models, settings, and chat history anywhere.
- **Fully offline after setup** – once models are downloaded, everything runs locally and your data never leaves the machine.
- **Runs in isolation** – does not interfere with any existing Ollama or Hollama installations.
- **Perfect for quick start** – ideal for exploring local LLMs or running experiments without committing to a full install.

---

#### About
Built by the team behind [EKHOS AI](https://ekhos.ai) - a professional-grade local AI transcription app delivering unlimited transcription, high accuracy, and secure data control for professionals in legal, medical, and other privacy demanding workflows.
