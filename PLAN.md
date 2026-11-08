# Mappa Viaggi: piano e revisione

Pagina sola su GitHub Pages (https://robb2000fred.github.io/mappa-viaggi/), senza login, installabile sul telefono (PWA).
Percorsi e preferiti salvati nel browser e sincronizzati tra i dispositivi di Fred con Supabase (codice famiglia).

## Obiettivo di questa revisione (8 nov 2026)

L'app è già costruita e pubblicata. Si chiede una revisione indipendente di:

1. **Sicurezza**: file nel repository, progetto Supabase (funzioni `leggi`/`scrivi`, RLS, chiave publishable nella pagina),
   service worker, link `#r=`/`#f=` ricevuti dall'esterno, dati inseriti dall'utente (nomi, ricerca Nominatim), XSS, costi.
2. **Funzionamento**: tappe A, B, C… con tocco sulla mappa; scheda del punto (Preferito / Togli); percorsi OSRM a piedi,
   bici, auto; salvataggio e riapertura; preferiti con icona e colore; data collegata; offline (cache tasselli, Salva zona);
   sincronizzazione (merge ultima-scrittura-vince per oggetto, cancellazioni con tombstone, pull/push).
3. **UI e UX** secondo le regole di Fred (vedi "Regole di stile"): telefono (barra fissa in basso, foglio dal basso,
   pulsanti ≥ 44 px) e PC/iPad (pannello laterale). Testi solo necessari, italiano semplice, accessibilità da tastiera e ARIA.
4. **Miglioramenti possibili**, in ordine di valore per l'utente, con costo e rischio di ognuno.

### Criteri di accettazione (osservabili)

- Nessun difetto di sicurezza "alto" aperto: chi ha solo la chiave publishable non legge né scrive dati altrui;
  nessun segreto nel repository; nessun testo utente o esterno finisce in HTML senza `esc()`.
- Un percorso A→B→C creato sul telefono (375×812) si salva, compare in "Percorsi", si riapre e si vede sul PC con lo
  stesso codice famiglia.
- La pagina funziona senza rete dopo "Salva zona" sulla zona salvata (tasselli dalla cache, dati dal browser).
- Nessun elemento sovrapposto o tagliato a 375 px e a 1024 px; nessuno scorrimento orizzontale.

### Regole di stile (da rispettare)

Font Poppins servito in locale (non da Google); bottoni ≥ 44 px (principali 52 px) con angoli 12 px, non a pillola;
tendine solo con il pezzo "tendina rotonda"; date a blocchi (numero grande + mese) e calendario in finestra;
tema chiaro e scuro; niente testi decorativi; etichette sopra i campi; `scrollbar-gutter: stable`;
tutto usabile da tastiera con focus visibile; ARIA sui componenti fatti a mano.

### Perimetro

In perimetro: `index.html`, `sw.js`, `manifest.webmanifest`, `supabase.sql`, `README.md`, `.gitignore`, `fonts/`, `vendor/`, `icons/`.
Fuori perimetro: `taccuino.html`, `taccuino-inline.js`, `patch_taccuino.py` (copia di lavoro di un'altra app, ignorati da git).
Correzioni autorizzate da Fred l'8 nov 2026 ("Sì, correggi tutto"): vedi "Correzioni (round 2)". Costruttore: Claude.
Dopo la costruzione: ispezione Codex in sessione fresca con base = commit 77ab92f.

### Verifica (prove che il coordinatore esegue, il revisore no)

```text
# 1. Sintassi del JavaScript inline (nessun node: si usa Code.exe come runtime)
ELECTRON_RUN_AS_NODE=1 "$LOCALAPPDATA/Programs/Microsoft VS Code/Code.exe" <scratch>/check-mappa.js <scratch>/mappa-inline.js
# atteso: SINTASSI OK

# 2. Supabase: la tabella non è leggibile con la chiave publishable (atteso 401)
curl -s -o /dev/null -w "%{http_code}" "$U/rest/v1/famiglie?select=*" -H "apikey: $K" -H "Authorization: Bearer $K"
# 3. Codice corto rifiutato (atteso: "codice non valido")
curl -s -X POST "$U/rest/v1/rpc/leggi" -H "Content-Type: application/json" -H "apikey: $K" -H "Authorization: Bearer $K" -d '{"codice":"corto"}'
# 4. Codice sconosciuto → {} (nessun dato altrui)
curl -s -X POST "$U/rest/v1/rpc/leggi" ... -d '{"codice":"altro-codice-xxxxx-yyyyy-zzzzz"}'
# 5. Nessun segreto nel repo (atteso: nessuna riga)
git grep -n -i "sb_secret\|service_role\|password" -- . ':!PLAN.md'

# 6. Browser integrato a 375×812 e 1024×768: tocco → A, tocco → B con percorso, Preferito/Togli, Salva, riapri,
#    codice famiglia creato su un'origine e collegato sull'altra: il preferito compare.
```

Risultati già ottenuti l'8 nov 2026: 1 → SINTASSI OK; 2 → 401; 3 → "codice non valido"; 4 → {}; 6 → tutte le prove passate
nel browser integrato (localhost e sito pubblicato).

## Sicurezza e dati

**Modello delle minacce.** Chi potrebbe attaccare: un curioso che trova il link del sito (pubblico), uno spammer
che chiama le funzioni del database a caso, chi riceve un link `#r=`/`#f=` costruito ad arte. Cosa vuole: leggere o
rovinare i percorsi, riempire il database, far eseguire codice nella pagina. Cosa si perde al massimo: l'itinerario
di un viaggio (nessun dato di altre persone, nessun pagamento, nessuna password). Il sito stesso non contiene dati: solo la pagina.

**Le 5 domande, per ogni funzione che tocca dati.**

Funzioni: `leggi(codice)` e `scrivi(codice, dati)` su Supabase, chiamate dal browser con la chiave publishable
(`sb_publishable_…`, pubblica per progetto, nella pagina).

1. *Chi può chiamarle senza passare dall'interfaccia?* Chiunque abbia la chiave publishable (è nella pagina, quindi
   chiunque). Senza il codice famiglia però `leggi` restituisce `{}` e `scrivi` crea una riga vuota a sé:
   non si arriva ai dati di Fred. La tabella non è leggibile direttamente (RLS attiva, nessuna policy, privilegi tolti: verificato, 401).
2. *Se qualcuno cambia un numero o un id?* L'unico id è il codice famiglia: 4 gruppi da 5 caratteri su un alfabeto di 31
   (circa 99 bit), generato con `crypto.getRandomValues`, non indovinabile per tentativi. Un codice sbagliato apre una famiglia vuota.
3. *Se la chiama un milione di volte?* Supabase limita le richieste del piano gratuito; in più `scrivi` crea al
   massimo 20 famiglie e rifiuta dati sopra 3 MB, quindi lo spam non riempie il database. Nel peggiore dei casi
   il progetto gratuito si ferma per un po': i dati restano nel browser dei dispositivi.
4. *Se una chiave finisce su GitHub?* La chiave publishable è pensata per stare nella pagina: da sola non legge nulla
   (vedi 1). La password del database e la chiave `sb_secret_` non entrano mai nel codice né in git.
   Il codice famiglia non va mai scritto nel repository.
5. *Chi paga?* Nessuno: piano gratuito Supabase senza carta, account a nome di Fred (i dati sono suoi).
   Tetto di spesa: non esiste spesa.

**OWASP Top 10, stato.** Controllo accessi: coperto dal codice segreto + funzioni security definer (non c'è
login per scelta). Configurazione: RLS attiva, tabella non esposta, "expose new tables" spento. Catena di fornitura:
Leaflet 1.9.4 servito in locale, font in locale, nessuna libreria da CDN; tasselli OSM/Esri, Nominatim e OSRM sono
servizi esterni (solo dati, non codice). Crittografia: https di GitHub Pages e Supabase. Iniezione: le funzioni
usano parametri, i dati sono jsonb; nella pagina ogni testo passa da `esc()`. Autenticazione: assente per scelta
(il codice famiglia fa da chiave condivisa). Integrità: ultima scrittura vince, per oggetto, con cancellazioni
tracciate. Registri/avvisi: NON coperto (nessun log oltre a quelli di Supabase). Gestione errori: messaggi generici.

**Non fatto, dichiarato.** Prova con lettore di schermo: non fatta. Prova di carico: non fatta.
Prova offline su telefono vero: fatta solo da Fred, non strumentata.

## Correzioni (round 2): cosa cambia e come si prova

Rilievi del round 1 e disposizione. Tutti i rilievi tranne R04 (mitigato) e R09 (risolto togliendo la funzione) si correggono.

| Rilievo | Correzione | Prova |
|---|---|---|
| R01 (alto) | `scrivi` fa l'unione nel database. Ordine: `pg_advisory_xact_lock(hashtext(codice))` **prima** di leggere (serializza anche due prime scritture sullo stesso codice), poi lettura della riga, unione di `routes`/`favs` per `id` con `mod` maggiore, `del` con data maggiore, scarto degli oggetti con `del >= mod`, **controllo dei 3 MB sul documento unito** (rifiuto senza toccare la riga), salvataggio e ritorno del documento unito. Nuova funzione `unisci(a, b, del)`. Migrazione: `drop function if exists scrivi(text, jsonb)` + `create function` (il tipo di ritorno cambia) + revoke/grant ripetuti, in un solo script. La pagina accetta sia la vecchia risposta (timestamp) sia la nuova (documento): si può pubblicare la pagina prima o dopo lo script. **La pagina non sostituisce lo stato con la risposta**: la unisce con lo stato locale *corrente* (non con l'istantanea inviata), così una modifica fatta durante l'invio resta e, essendo `dirty`, riparte subito dopo. | Due `scrivi` con oggetti diversi sullo stesso codice → `leggi` li contiene entrambi; una cancellazione più recente vince; due prime scritture in parallelo su un codice nuovo → entrambi gli oggetti presenti; documento unito > 3 MB → rifiutato e riga intatta. |
| R02 | `pull` cattura `codice` e un contatore di connessione prima di ogni `await`; scarta risposte di una connessione precedente. | Lettura del codice; prova manuale: cambio codice durante il pull non scrive sul nuovo. |
| R03 | Bandiera `dirty`: ogni `persist()` locale la alza; a fine `pull`, se è alta, si riparte subito. | Salva durante una sincronizzazione: entro 2 s il server ha l'oggetto. |
| R04 | Limite famiglie 50, conteggio sotto `pg_advisory_xact_lock`. Rischio residuo dichiarato (riempimento da parte di chi ha il link): pulizia dal pannello Supabase. | Lettura SQL. |
| R05 | `routeToken++` in `newRoute`, `openRoute`, `clearStop`, `swap` e cambio mezzo, anche quando non parte una richiesta; la risposta si applica solo se token e tappe coincidono. | Lettura del codice. |
| R06 | `openRoute` e `swap` azzerano `S.pick` e ridisegnano la scheda. | Telefono: A→B→C, scheda su C, Inverti → scheda chiusa. |
| R07 | `LS.set` e `persist` restituiscono `true/false`; `saveRoute`/`saveFav` dicono "salvato" solo se `true`. | Simulazione: `localStorage.setItem` che lancia → toast di errore, nessun "salvato". |
| R08 | Ascolto dell'evento `storage`: le collezioni lette dal browser vengono **unite** (stessa `merge` per id/mod/tombstone) allo stato in memoria, non sostituite, e il risultato viene riscritto: così due schede che salvano dalla stessa istantanea finiscono con l'unione dei due salvataggi e l'invio al server parte dallo stato unito. La `merge` diventa **deterministica**: a parità di `mod` vince, nell'ordine, il valore maggiore di `name`, `at`, `date`, `icon`, `color`, `mode`, `distance`, `duration`, `lat`, `lon`, e infine il testo di `pts` e di `coords` (stessa sequenza nella funzione SQL `unisci`, confronto testuale campo per campo: così due versioni diverse dello stesso oggetto hanno sempre un vincitore comune); oggetti ordinati per `at` decrescente e poi `id`; chiavi di `del` ordinate. Residuo dichiarato: la rappresentazione testuale di `pts`/`coords` in SQL (jsonb) e in JavaScript differisce solo per gli spazi, quindi l'ordine tra due versioni coincide salvo casi di pura teoria e il gestore **riscrive solo se** il documento unito è diverso da quello su disco (confronto su JSON canonico), senza alzare `dirty` né inviare quando non cambia nulla: niente rimbalzi tra schede. Rischio residuo dichiarato: nessun lock tra schede (finestra di pochi ms). | Due schede: salvo A nella prima e B nella seconda senza ricaricare → entrambe mostrano A e B. |
| R09/R10 | Tolti il pulsante ⤓ "Salva zona", `downloadArea` e `tileXY`. Resta la cache dei tasselli visti (sw.js). **Stessa politica di zoom online e offline** (`maxNativeZoom` 19 sempre, niente ricostruzione del layer al cambio di rete): offline si usano esattamente i tasselli visti; gli zoom mai visti restano vuoti, documentato nel README. | Il pulsante non esiste; nessun riferimento a `downloadArea` né a `maxNativeZoom` condizionale. |
| R11 | Se `navigator.onLine === false` all'avvio o all'evento `offline`, la base passa a OSM (e il bottone Satellite lo dice). | Simulazione offline nel browser → base OSM. |
| R12 | Cache `mappa-app-v3` e `mappa-tiles-v1`; `activate` **copia i tasselli dalla vecchia `tiles-v1` nella nuova** (se esiste), poi cancella solo le cache note dell'app (`app-v1`, `app-v2`, `tiles-v1`) e quelle che iniziano con `mappa-` diverse dalle attuali. Le cache di altre app sullo stesso dominio non vengono toccate. | Lettura di sw.js; con una `tiles-v1` piena, dopo l'attivazione `mappa-tiles-v1` contiene le stesse voci. |
| R13 | `S.draftName` è `null` finché l'utente non tocca il campo ("nessuna modifica"), poi la stringa scritta, **anche vuota**; i ridisegni mostrano `S.draftName ?? nomeSalvato`. `openRoute`, `newRoute` e il salvataggio riuscito lo rimettono a `null`; un link `#r=` lo imposta al nome del link. | Scrivo un nome, arriva un ridisegno (pull) → il testo resta; svuoto il campo e arriva un ridisegno → resta vuoto; apro un percorso salvato → il campo mostra il suo nome. |
| R14 | Sul telefono il pannello chiuso ha `inert`; `openSheet` sposta il focus dentro, `closeSheet` lo riporta al pulsante che l'ha aperto. | Pannello chiuso: `panel.inert === true`; aperto: focus dentro. |
| R15 | Errore di `watchPosition` → `clearWatch` prima di azzerare l'id; `myPosition` pulisce watch e timer in ogni uscita. | Lettura del codice. |
| R16 | `newRoute` azzera `S.pendingDate`. | Lettura del codice. |
| R17 | Bersagli ≥ 44 px: ✕ ricerca, colori, lettere su PC, `.leaflet-touch .leaflet-bar a`. | Misura `getBoundingClientRect` ≥ 44 su quei controlli. |
| R18 | README riscritto: sincronizzazione con codice famiglia, dati nel browser, scollegamento, link condivisi vs dati sincronizzati, offline. | Lettura. |

Cosa NON cambia: struttura dei dati, link `#r=`/`#f=`, UI generale. La ricerca con Photon (commit 77ab92f di un'altra sessione) non è oggetto delle correzioni.

Prove a fine costruzione (oltre a quelle del round 1): sintassi JS; `scrivi` doppio e `leggi` (R01); prove nel browser integrato a 375×812 e 1024×768: tocco→A, tocco→B, Preferito/Togli, Salva, Inverti con scheda aperta (R06), misure 44 px (R17), `panel.inert` (R14), offline simulato → base OSM (R11).

## Correzioni (round 3): i 10 rilievi della seconda ispezione (MV-01..MV-10)

Autorizzate da Fred l'8 nov 2026 ("Sì, correggi"). Costruttore: Claude (sessione coordinatrice). Commit base pre-costruzione: aa19f08.

| # | Cosa cambia | Come si prova |
|---|---|---|
| MV-03 | Percorsi, preferiti e cancellazioni stanno in UNA chiave `mappa-dati` `{v,routes,favs,del}`: `persist()` fa una sola `setItem` (tutto o niente). Le tre chiavi vecchie (`mappa-percorsi`, `mappa-preferiti`, `mappa-del`) si leggono solo se `mappa-dati` manca e si cancellano dopo il primo salvataggio riuscito. | Avvio con le tre chiavi vecchie → dopo l'avvio esiste solo `mappa-dati` con gli stessi dati. |
| MV-01 | All'avvio i dati letti passano da `merge(disk, {})`: le cancellazioni ricordate (tombstone) tolgono i percorsi/preferiti con `mod` ≤ data di cancellazione. Nell'evento `storage` il confronto è con ciò che è scritto davvero (`canon([disk.routes, disk.favs, disk.del])`), non con la sua copia ripulita: un disco "sporco" viene riscritto. | Disco con percorso X e `del[X]` più recente → all'avvio X non c'è; evento storage con lo stesso caso → il disco viene riscritto senza X. |
| MV-02 | Nell'evento `storage`, se la memoria cambia (anche senza riscrivere il disco) si segna `dirty` e si fa `push()`. | Scheda 2 scrive un percorso nuovo → scheda 1 lo mostra e programma la sincronizzazione. |
| MV-04 | `pull()` legge il risultato di `persist()`: se fallisce lo stato diventa `nosave` (chip "Scaricato, ma non salvato sul dispositivo") e compare il toast NO_SAVE. | Lettura del codice (localStorage pieno non simulabile qui). |
| MV-05 | `setCodice()` scrive prima il codice (`LS.set`, o `LS.del` per scollegare) e, se la scrittura fallisce, avvisa e non cambia stato. | Lettura del codice. |
| MV-06 | `sw.js`: su un tassello assente in `mappa-tiles-v1` si guarda anche la vecchia `tiles-v1` (`caches.match(url, {cacheName})`), si serve e si copia nella nuova. | Lettura del codice. |
| MV-07 | `applyHash` riusa un percorso salvato solo se coincidono mezzo, nome, data, numero di tappe, coordinate e nomi delle tappe; altrimenti apre una bozza con i dati del link. | Link con le stesse tappe ma nome diverso → bozza "Altro nome" non salvata; link identico → riapre il salvato. |
| MV-08 | `openSheet` registra chi apre solo se non è il body; `closeSheet` riporta il focus anche quando l'elemento premuto è stato rimosso (focus già sul body). | 375×812: apri menu, togli il focus, chiudi → focus su `bar-menu`. |
| MV-09 | Tendina: `role="combobox"`, `aria-controls` verso la lista con id, ogni voce ha un id, `aria-activedescendant` segue la voce evidenziata e sparisce alla chiusura. | DOM: `[role=combobox][aria-controls]` punta a una lista esistente. |
| MV-10 | Limite 26 tappe dentro `setStop` (vale per tocco, ricerca, GPS) e in `applyHash` (link con più di 26 tappe ignorato). | Link con 27 tappe → 0 tappe; con 26 → 26; tocco in più → toast "Hai già 26 tappe". |
| extra | `drawSaved` non disegna il tracciato di un percorso senza `coords` (dato rovinato) invece di andare in errore. | Percorso senza coords in memoria → nessun errore in console. |

Prove eseguite dal coordinatore l'8 nov 2026 nel browser integrato (localhost:8790): tutte quelle della colonna "Come si prova" marcate come prova, con esito positivo. Non provati: localStorage pieno (MV-04/05), service worker con migrazione interrotta (MV-06), lettore di schermo (MV-09).

### Round 3, dopo l'ispezione 3 (Codex, 4 rilievi R3-01..R3-04, tutti accettati)

| # | Cosa cambia | Come si prova |
|---|---|---|
| R3-01 | `setCodice()` restituisce true/false; "Codice creato" e "Dispositivo scollegato" compaiono solo se la scrittura è riuscita. | Lettura del codice. |
| R3-02 | `readDisk()` legge `mappa-dati` E le chiavi vecchie se esistono ancora (una scheda rimasta aperta con la versione precedente le scrive): si accostano e `merge()` toglie i doppioni all'avvio e nell'evento `storage`, che ora ascolta anche le chiavi vecchie. | Avvio con `mappa-dati` + `mappa-percorsi` scritto "dopo" → entrambi i percorsi presenti, chiavi vecchie tolte. |
| R3-03 | Le chiavi vecchie si tolgono dentro `persist()` al primo salvataggio riuscito, quando capita (non solo all'avvio); se il salvataggio all'avvio fallisce compare NO_SAVE e le chiavi vecchie restano. Respinto: staging in IndexedDB (sproporzionato: i dati sono pochi KB contro 5 MB di quota). | Come sopra; quota piena non simulata. |
| R3-04 | `openRoute()` di un percorso senza tracciato apre le tappe come bozza e ricalcola (`routeIfReady`); `drawRoute()` non chiama Leaflet senza almeno 2 coordinate. | "Apri" su un percorso senza `coords` → tappe A/B, ricalcolo OSRM, nessun errore in console. |
