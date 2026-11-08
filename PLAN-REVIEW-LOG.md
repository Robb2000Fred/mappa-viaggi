# Registro della revisione claudex-loop (append-only)

- Data: 8 nov 2026
- Host: Claude Code (Fable 5.1). Pianificatore: questa sessione. Revisore del piano: Codex CLI 0.165.0 (modello: default della CLI, non forzato). Costruttore: Claude (l'app è già scritta da questa sessione). Ispettore del codice: sessione Codex nuova.
- Piano: PLAN.md. Round massimi: 5 revisioni del piano, 2 ispezioni. Ispezione: attiva.
- Perimetro: revisione di sicurezza, funzionamento, UI/UX e miglioramenti dell'app pubblicata. Nessuna modifica al codice autorizzata da questa revisione.
- Base per l'ispezione: commit f1490f4 (primo commit, scheletro iniziale); tutto il resto è opera di Claude.
- Diagnostica fuori dal checkout: C:\Users\FRED1\AppData\Local\Temp\claude\23a51c0aca38b76b\e1484d14-2164-4a77-876b-1e68c1c2a603\scratchpad\claudex\

## Prove eseguite dal coordinatore (8 nov 2026, prima della revisione)
- Sintassi JS inline: SINTASSI OK.
- Tabella `famiglie` letta direttamente con chiave publishable: 401.
- `leggi("corto")`: "codice non valido". `leggi(codice sconosciuto)`: {}. Chiamata senza chiave: 401.
- `scrivi` con 3,1 MB: "troppi dati".
- `git grep` di sb_secret / service_role / password: nessuna riga.

## Round 1: revisione del piano e del codice (Codex)
- Risultato: C:\Users\FRED1\AppData\Local\Temp\claude\23a51c0aca38b76b\e1484d14-2164-4a77-876b-1e68c1c2a603\scratchpad\claudex\review1\claudex-f77zqcrq\result.json
- Sessione Codex: 01a1bb95-d93b-7611-9929-79ee7dfc45f5. Modello richiesto: nessuno (default CLI). Modello applicato (dal rollout): gpt-6.1-sol, effort high. CLI: codex-cli 0.165.0.
- SHA256 del piano: 2c3edd5a9a6c299db85489173db50b24bec0b04c929b61421953a80772332298
- Verdetto: REVISE. 18 rilievi (R01 alto; R02-R15 medi; R16-R18 bassi). Copertura dichiarata: PLAN.md, index.html, sw.js, supabase.sql, README, manifest, .gitignore, font, inventario asset, policy OSM.
- Limiti dichiarati dal revisore: nessuna esecuzione, nessun browser, nessun accesso al pannello Supabase, taccuino escluso.
- Testo completo dei rilievi: nel result.json sopra; sintesi in italiano in RAPPORTO-REVISIONE.md.

### Disposizioni del coordinatore (Claude)
- Accettati, da correggere se Fred autorizza: R01, R02, R03, R05, R06, R07, R10, R11, R12, R13, R14, R15, R16, R17, R18.
- R09 accettato: "Salva zona" viola la policy OSM (sez. 4). Proposta: rimuovere il prefetch, tenere la cache dei tasselli visti durante la navigazione.
- R04 accettato in parte: senza server non esiste "provisioning fidato"; mitigazione proposta: limite 50 famiglie, pulizia manuale dal pannello Supabase; rischio accettato (non tocca i dati esistenti).
- R08 accettato come bassa priorità (due schede sullo stesso dispositivo): listener `storage` se si fanno le altre correzioni.
- Nessuna modifica al codice eseguita in questo round: in attesa della decisione di Fred. Il piano cambierà con la lista correzioni e andrà rivisto (round 2) prima di costruire; dopo la costruzione, ispezione Codex in sessione fresca con base = commit attuale.

## Round 2-5: revisione del piano delle correzioni (Codex, stessa sessione 01a1bb95-…, gpt-6.1-sol, effort high)
- Round 2 (review2/claudex-sf5ya7ej, piano d4fe64a8…): REVISE, 8 rilievi (R2-01 alto: la risposta di scrivi non deve sostituire lo stato locale; R2-02 lock prima della lettura; R2-03 limite 3 MB sul documento unito; R2-04 drop/recreate; R2-05 storage: unire, non sostituire; R2-06 stessa politica di zoom online/offline; R2-07 migrare tiles-v1; R2-08 respinto: il render usa draftName ?? nome salvato). Tutti accettati tranne R2-08; piano aggiornato.
- Round 3 (review3/claudex-2np60p0j, piano 6296eb0e…): REVISE, 2 rilievi (R3-01 ciclo tra schede per ordine non deterministico; R3-02 nome svuotato apposta). Accettati; piano aggiornato (merge deterministica, draftName null).
- Round 4 (review4/claudex-hj3nz2ul, piano 42ef553a…): REVISE, 1 rilievo (R4-01 pari merito su mod). Accettato: spareggio name/at.
- Round 5 (review5/claudex-jql09rcm, piano fdeee98d…): REVISE, 1 rilievo (R5-01 lo spareggio deve coprire anche date/icon/color…). Accettato: spareggio campo per campo (name, at, date, icon, color, mode, distance, duration, lat, lon, pts, coords) identico in JS e SQL; piano aggiornato DOPO il round 5.
- Limite di 5 round raggiunto senza APPROVED. Posizione del coordinatore: tutti i rilievi sono stati accolti; l'ultimo è nel piano ma non è stato rivisto. Decisione sul come procedere (round extra o costruzione senza approvazione formale, registrata come tale) rimessa a Fred.
- Incidente di processo: il patch è stato applicato per errore al repository due volte durante le prove a secco e subito annullato con `git checkout` (nessun commit, nessuna pubblicazione). Lo script ora richiede la cartella di destinazione esplicita.

## Costruzione (Claude), 8 nov 2026
- Fred ha scelto "Sì, procedi" dopo i 5 round: costruzione SENZA approvazione formale del piano (percorso "unreviewed-spec", registrato come tale). Commit di base: 77ab92f.
- Applicati: patch_round2.py (index.html, sw.js), supabase.sql riscritto (drop/create scrivi, unisci), README riscritto.
- Prove a fine costruzione (browser integrato): 375×812: tocco→A/B/C con percorso; pannello chiuso inert=true, aperto inert=false con focus dentro; "Salva zona" assente; Inverti chiude la scheda del punto; nome scritto conservato dopo ridisegno; ✕ ricerca, colori, lettere, zoom = 44×44; evento storage → preferito dell'altra scheda unito; offline con Satellite → base "mappa". 1024×768: percorso A→B, nessuno scorrimento orizzontale, lettere 44×44, codice famiglia creato → "Sincronizzato" con lo scrivi vecchio (compatibilità). Sintassi JS e sw.js OK.
- Commit della costruzione: vedi `git log` (pubblicato su GitHub Pages). Il nuovo supabase.sql va ancora incollato da Fred nell'SQL Editor.

## Ispezione 1 (Codex, sessione fresca 01a1bbc6-1e56-7c51-9fb9-0f09ada1b974, gpt-6.1-sol, base 77ab92f, unreviewed-spec)
- Risultato: scratchpad\claudex\inspect1\claudex-8xi7cbj8\result.json. Verdetto: REVISE, 10 rilievi (IR01-IR09 medi, IR10 basso).
- Disposizioni: tutti accettati e corretti (patch_fix1.py): IR01 scollega passa da setCodice (conn++); IR02 a fine richiesta vecchia riparte la sincronizzazione del codice nuovo; IR03 evento storage su mappa-codice; IR04 confronto su JSON canonico (chiavi ordinate); IR05 tiles-v1 cancellata solo se la copia riesce; IR06 salvataggi/date/eliminazioni ripristinano lo stato se il browser non scrive; IR07 link #r= azzera scheda, percorso e richieste; IR08 focus e cursore nel campo nome conservati, ritorno del focus su bar-menu; IR09 scritture in cache legate all'evento (waitUntil) con clone prima del ritorno; IR10 calendario 44×44 a 375 px.
- Prove (browser 375×812): preferito e percorso con localStorage bloccato → avviso, nessun "Salvato", nessun doppione al secondo tentativo; focus e cursore nel nome conservati dopo un ridisegno; giorni del calendario 44×44. Sintassi JS e sw.js OK.

## Ispezione 2 (Codex, sessione fresca 01a1bbcc-feae-7d31-9ccc-2e1641bd2d9e, gpt-6.1-sol, base 77ab92f, unreviewed-spec)
- Risultato: scratchpad\claudex\inspect2\claudex-tnfg9ozv\result.json. Verdetto: REVISE, 10 rilievi (MV-01..07 medi, MV-08..10 bassi): convergenza tra schede con tombstone (MV-01/02), persist non atomica su tre chiavi (MV-03), pull/setCodice ignorano il fallimento del salvataggio locale (MV-04/05), lettura della vecchia cache tasselli se la migrazione fallisce (MV-06), link #r= con stesse tappe ma dati diversi riapre il percorso locale (MV-07), focus alla chiusura dopo salvataggio preferito (MV-08), tendina mezzo senza active-descendant (MV-09), limite 26 tappe solo sul tocco (MV-10).
- Budget ispezioni esaurito (2 di 2). Nessuna correzione applicata per questi rilievi: decisione rimessa a Fred. Eventuali correzioni ulteriori sarebbero NON ispezionate e vanno dichiarate come tali.
- Stato: tutte le modifiche fino al commit 2bea15a sono state ispezionate da Codex (ispezione 2 ha coperto il diff completo da 77ab92f).
