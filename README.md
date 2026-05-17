# AgentRealm

---

## 🏛️ Filozofija "Clean Root"

AgentRealm je dizajniran da tvoj rad drži u fokusu. Sva kompleksna automatizacija, RAG sustavi i agentske sandbox okoline skriveni su u `.ai/` direktoriju, dok korijen repozitorija ostaje čist i pregledan.

| Direktorij | Svrha                                              | Fokus          |
| :--------- | :------------------------------------------------- | :------------- |
| 🚀 `src/`  | Glavni kod projekta, algoritmi i skripte.          | **Tvoj Rad**   |
| 📝 `docs/` | Dokumentacija, seminari, LaTeX i izvještaji.       | **Tvoj Rad**   |
| 📊 `data/` | Podaci podijeljeni na RAG izvore i projektne baze. | **Tvoj Rad**   |
| ⚙️ `.ai/`   | "Engine Room" — skripte, agenti i infrastruktura.  | Infrastruktura |

---

## ⚡ Pokretanje novog projekta

Spremite sate podešavanja jednom naredbom. AgentRealm automatski konfigurira virtualne okoline, instalira ovisnosti i povezuje se s tvojim globalnim znanjem.

### 🛠️ Konfiguracijske opcije

Prilikom pokretanja bootstrap skripte, dostupni su sljedeći parametri:

| Parametar    | Opis                  | Vrijednosti               | Default      | Napomena                              |
| :----------- | :-------------------- | :------------------------ | :----------- | :------------------------------------ |
| **`-name`**  | Identitet projekta    | `Text`                    | _(Obavezno)_ | Ažurira `project.yaml` i `STATE.md`.  |
| **`-brain`** | Mod dijeljenog znanja | `none`, `global`, `local` | `global`     | Povezuje SSOT vještine i lekcije.     |
| **`-rag`**   | AI Retrieval Mod      | `none`, `cloud`, `local`  | `none`       | Određuje ovisnosti i ML modele.       |
| **`-ide`**   | Editor konfiguracija  | `vscode`, `antigravity`   | `vscode`     | Postavlja `.vscode` i agent sandboxe. |

#### 🤖 Usporedba RAG modova

| Mod         | Otisak  | Zahtjevi         | Prednosti                            |
| :---------- | :------ | :--------------- | :----------------------------------- |
| **`none`**  | ~0 MB   | —                | Brzo, bez ML ovisnosti.              |
| **`cloud`** | ~200 MB | `GOOGLE_API_KEY` | Lagano, koristi Gemini API (online). |
| **`local`** | ~1.2 GB | GPU (opcionalno) | Privatno, radi 100% offline.         |

### 🚀 Primjeri inicijalizacije

**Windows (PowerShell):**

```powershell
.\\.ai\\scripts\\helpers\\bootstrap-project.ps1 -name "Moj_Projekt" -brain global -rag cloud
```

_Zadana globalna putanja:_ `~/.agentbrain` (Windows) / `~/.agentrealm` (Linux)

**Linux / macOS (Bash):**

```bash
./.ai/scripts/helpers/bootstrap-project.sh --name "Moj_Projekt" --brain global --rag cloud
```

_Zadana globalna putanja:_ `~/.agentrealm`

#### 🧠 Modovi mozga (Brain Modes)

- **`none`**: Projekt je izoliran, ne koristi se dijeljeno znanje.
- **`global`**: Koristi se SSOT direktorij u korisničkom profilu (`$HOME`). Ako direktorij ne postoji, AgentRealm će automatski pokušati povući (clonirati) **AgentBrain** repozitorij na tu lokaciju.
- **`local`**: Brain se kreira unutar samog projekta (`.ai/brain/`). Idealno za specifične istraživačke projekte.

---

## 🔄 Workflow: Human + Agent Collaboration

AgentRealm koristi **Git Worktrees** za potpunu izolaciju zadataka. Agent nikada ne radi direktno na tvojoj `main` grani.

1.  **Start Task**: Kreiraj sandbox za novi zadatak.
    ```powershell
    .\\.ai\\scripts\\git\\new-task-worktree.ps1 "implement-feature-x"
    ```
2.  **Delegate**: Pošalji agenta u akciju.
    ```powershell
    .\\.ai\\scripts\\agents\\run_claude_task.ps1 .ai\\worktrees\\implement-feature-x
    ```
3.  **Review & Merge**: Provjeri rezultat i spoji u projekt.
    ```powershell
    .\\.ai\\scripts\\helpers\\check-all.ps1
    .\\.ai\\scripts\\git\\cleanup-worktrees.ps1 .ai\\worktrees\\implement-feature-x
    ```

---

## 🧠 RAG & Global Knowledge

Poveži sve svoje projekte u jednu inteligentnu mrežu.

- **Global Brain**: Dijeljeni repozitorij (`~/.agentbrain`) koji čuva tvoje vještine (`skills`) i naučene lekcije kroz sve projekte.
- **CRAG Pipeline**: Agent prvo pretražuje tvoju lokalnu literaturu (`data/rag/sources`), zatim Global Brain, a po potrebi se konzultira s web pretragom.

### Postavljanje Cloud RAG-a (Gemini)

1. Preuzmi ključ na [Google AI Studio](https://aistudio.google.com/apikey).
2. Dodaj u `.env`: `GOOGLE_API_KEY=tvoj_kljuc`.

---

## 🎓 Akademski Standardi (LaTeX)

AgentRealm dolazi s ugrađenim predlošcima za **FSB (Fakultet strojarstva i brodogradnje)**:

- ✅ **Seminar** | ✅ **Thesis** | ✅ **Paper**

Automatski build, SyncTeX podrška i savršeno formatiranje bez ručnog namještanja margina.
Pogledaj [docs/instructions.md](docs/instructions.md) za detaljan vodič kroz pisanje.

---

## 🛡️ Upravljanje & Sigurnost

- **STATE.md**: "Live Brain" projekta — uvijek znaš što je sljedeće na redu.
- **AGENTS.md**: Stroga pravila ponašanja za AI agente.
- **Git Guardrails**: Automatska zaštita od slučajnog commita na krive grane ili curenja API ključeva.

---
