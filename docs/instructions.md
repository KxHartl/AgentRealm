# Detaljne upute za rad u AgentRealm-u

Ovaj dokument pruža dublji uvid u to kako efikasno koristiti AgentRealm sustav za razvoj koda, obradu podataka i pisanje akademskih radova.

## 1. Arhitektura i uloge (Agents)

Sustav je dizajniran oko specijaliziranih uloga. Kada zadaješ zadatak agentu, možeš naglasiti koju ulogu treba preuzeti:

- **Planner**: Pomaže u dekompoziciji velikih ciljeva u manje zadatke u `STATE.md`.
- **Coder**: Specijaliziran za pisanje koda u `src/` i rješavanje bugova.
- **Analyst**: Fokusiran na obradu podataka unutar `data/process/`. Čita `raw/` i piše u `output/`.
- **Writer**: Pomaže u pisanju LaTeX/Markdown dokumentacije u `docs/`.
- **Reviewer (QA)**: Provjerava kod i tekst prije spajanja u `main`.

## 2. Detaljan razvojni ciklus (Workflow)

### Kreiranje zadatka
Uvijek započni s `ai/scripts/git/new-task-worktree.ps1 <slug>`. 
*Zašto?* To izolira promjene. Ako agent pogriješi, tvoj glavni radni prostor (`main`) ostaje netaknut.

### Rad s agentom
Možeš koristiti različite skripte ovisno o modelu koji preferiraš:
- `.\\ai\\scripts\\agents\\run_gemini_task.ps1` (Brz, dobar za RAG)
- `.\\ai\\scripts\\agents\\run_claude_task.ps1` (Odličan za kompleksno kodiranje)

### Provjera kvalitete
Prije nego završiš zadatak, pokreni:
```powershell
.\\ai\\scripts\\helpers\\check-all.ps1
```
Ova skripta provjerava:
1. Jesu li svi zahtjevi iz `ai/config/requirements.list` ispunjeni.
2. Ima li sintaktičkih pogrešaka u kodu.
3. Jesu li podaci u `data/process/` konzistentni.

## 3. Rad s podacima (Analyst Workflow)

AgentRealm strogo odvaja podatke:
- **`data/rag/`**: Ovdje stavljaš literaturu (PDF, slajdovi). Agent to koristi samo kao znanje.
- **`data/process/raw/`**: Tvoji sirovi ulazni podaci (npr. CSV mjerenja). **Nikada ne mijenjaj ove datoteke.**
- **`data/process/output/`**: Ovdje agent sprema rezultate obrade, grafikone i izvještaje.

## 4. Pisanje seminara i LaTeX-a

1. **Predlošci**: Svi FSB predlošci su u `docs/templates/`.
2. **Markdown-to-LaTeX**: Preporuča se da agent prvo napiše sadržaj u Markdownu radi lakše korekcije, a zatim ga prebaciš u `.tex` predložak.
3. **Build**: Koristi `.\\ai\\scripts\\helpers\\build-docs.ps1` za generiranje PDF-a.

## 5. Global Brain i sinkronizacija

Ako radiš na više projekata, tvoje "naučene lekcije" i nove vještine (skills) spremaju se u `~/.agentbrain`.
- Za sinkronizaciju vještina iz Global Braina u trenutni projekt:
  ```powershell
  .\\ai\\scripts\\agents\\sync-brain.ps1
  ```

---

*Savjet: Ako zapneš, pokreni `.\\ai\\scripts\\helpers\\project-status.ps1` za brzi pregled stanja projekta i preporučenih idućih koraka.*
