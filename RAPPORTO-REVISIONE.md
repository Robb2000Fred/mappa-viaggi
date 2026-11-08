# Rapporto di revisione indipendente: Mappa Viaggi (8 nov 2026)

Revisore: Codex CLI 0.165.0 (modello applicato: gpt-6.1-sol, impegno alto), sessione di sola lettura, piano `PLAN.md`.
Verdetto: **REVISE** (da correggere prima di dirla "approvata"). 18 rilievi: 1 alto, 14 medi, 3 bassi.
Ogni rilievo l'ho ricontrollato io sul codice: tutti confermati. Le prove sul database (401 sulla tabella, codice corto
rifiutato, codice sconosciuto vuoto, 3 MB rifiutati, nessun segreto nel repository) le ho rifatte io e passano.

## Cosa è sicuro oggi (confermato)

- Chi ha solo la chiave `sb_publishable_` (è nella pagina, lo sa chiunque) non legge né scrive i tuoi dati:
  la tabella risponde 401 e senza codice famiglia si ottiene un vuoto.
- Nessuna password o chiave segreta nel repository né nella cronologia controllata.
- Nessun testo scritto da te o preso da internet finisce nella pagina senza passaggio di sicurezza (`esc()`).
- Nessuna libreria da siti esterni: Leaflet e i font sono nella cartella dell'app.
- Nessun costo: piano gratuito, nessuna carta.

## Rilievi, in ordine di importanza, con la mia valutazione

| # | Gravità | Cosa succede | Cosa farei | Sforzo |
|---|---|---|---|---|
| R09 | media, **ma è la più seria** | "Salva zona" scarica in blocco centinaia di pezzi di mappa da OpenStreetMap. Le loro regole lo vietano espressamente e possono bloccare il sito senza avviso. | Togliere il pulsante "Salva zona". Resta il salvataggio dei pezzi che guardi normalmente mentre sei online (quello è permesso): per avere una zona offline la scorri una volta con internet. | basso |
| R01 | alta | Se PC e telefono sincronizzano nello stesso istante, l'ultimo che scrive cancella le novità dell'altro, e tutti e due dicono "Sincronizzato". Per una persona sola è raro, ma possibile. | Far fare l'unione (merge) al database dentro `scrivi`, così nessuno sovrascrive l'altro. | medio |
| R12 | media | Il service worker, quando si aggiorna, cancella TUTTE le cache del dominio robb2000fred.github.io, anche quelle di altre tue app future ospitate lì. | Dare alle cache un prefisso "mappa-" e cancellare solo quelle. | basso |
| R10 | media | "Salva zona" prepara la lista dei pezzi PRIMA di controllare se sono troppi: con la mappa molto lontana può bloccare il telefono. | Decade se si toglie "Salva zona"; altrimenti contare prima. | basso |
| R11 | media | Se eri su "Satellite" quando salvi la zona, offline la mappa è bianca (il satellite non si salva). | Offline passare sempre alla mappa normale. | basso |
| R04 | media | Chiunque conosca il link può creare 20 "famiglie" vuote con codici inventati e bloccare la creazione di codici nuovi (i tuoi dati non si toccano). | Senza un server non si evita del tutto. Alzare il limite a 50 e sapere che le righe inutili si cancellano dal pannello Supabase. | basso |
| R03 | media | Se salvi qualcosa mentre una sincronizzazione è in corso, quella novità parte solo alla sincronizzazione successiva (non si perde: si ritarda). | Segnare "ho modifiche in sospeso" e risincronizzare subito dopo. | basso |
| R02 | media | Se cambi codice famiglia proprio mentre sta leggendo, potrebbe scrivere i dati del vecchio codice nel nuovo. | Scartare le risposte arrivate dopo un cambio di codice. | basso |
| R05 | media | Una risposta lenta del calcolo percorso può disegnare il percorso vecchio sopra uno aperto dopo. | Annullare le richieste in sospeso a ogni cambio. | basso |
| R06 | media | Con la scheda di una tappa aperta, se premi "Inverti" o apri un altro percorso, "Togli" può togliere la tappa sbagliata. | Chiudere la scheda in quei casi. | basso |
| R07 | media | Se la memoria del browser è piena, il salvataggio fallisce ma la pagina dice "salvato". | Dire "salvato" solo se ha scritto davvero. | basso |
| R13 | media | Mentre scrivi il nome del percorso, un aggiornamento in arrivo può cancellarti il testo. | Tenere il testo scritto durante i ridisegni. | basso |
| R14 | media | Sul telefono il pannello chiuso resta "visibile" alla tastiera e ai lettori di schermo. | Marcarlo `inert` da chiuso e spostare il focus. | basso |
| R15 | media | Un errore del GPS può lasciare il rilevamento acceso con il pulsante spento. | Spegnere sempre il rilevamento in caso di errore. | basso |
| R08 | media (per me bassa) | Due schede del browser aperte insieme sullo stesso dispositivo possono sovrascriversi. | Caso raro; si può ascoltare l'evento `storage`. | basso |
| R16 | bassa | Dopo aver aperto un link con data e poi "Nuovo percorso", la data resta appiccicata al percorso nuovo. | Azzerarla su "Nuovo". | basso |
| R17 | bassa | Alcuni pulsanti sono sotto i 44 px (✕ ricerca 38, colori 36, lettere PC 40, zoom Leaflet 30 su touch). | Portarli a 44. | basso |
| R18 | bassa | Il README dice ancora che PC e iPad non si vedono: ora si sincronizzano. | Aggiornare il README. | basso |

## UI e UX: cosa dice il revisore e cosa aggiungo io

- Confermate le regole: Poppins locale, angoli 12 px, tema chiaro/scuro, barra fissa in basso sul telefono.
- Da sistemare: bersagli sotto 44 px (R17), pannello chiuso non inerte (R14).
- Non provato da nessuno: lettore di schermo (NVDA), uso solo da tastiera di tutta la pagina, offline sul telefono vero in modo strumentato.

## Miglioramenti possibili (oltre ai rilievi), in ordine di valore

1. **Navigazione "sei qui" sul percorso**: puntino blu che si muove sul tracciato mentre cammini (già c'è il GPS: manca solo seguirlo). Costo basso.
2. **Etichette delle tappe nel percorso salvato** anche su B, C… (oggi il nome è solo su A). Costo basso.
3. **Esporta/Importa** un file di backup dei percorsi (oltre a Supabase), per non dipendere da un servizio. Costo basso.
4. **Collega al Taccuino per davvero**: oggi "Collega" salva solo una data. Il passo vero è far comparire il percorso nel giorno del Taccuino. Costo medio.
5. **Mappa offline fatta bene**: un fornitore che permetta il salvataggio (a pagamento o self-hosted) se "scorrere la zona prima" non basta. Costo medio-alto.

## Limiti dichiarati

- Il revisore ha letto il codice, non ha eseguito la pagina né il telefono. Le prove di funzionamento le ho fatte io nel
  browser integrato (375×812 e 1024×768) e Fred sul suo telefono.
- Il revisore non ha accesso al pannello Supabase: le protezioni le ho verificate io dall'esterno (risultati sopra).
- Nessuna modifica è stata fatta in base a questo rapporto: le correzioni partono solo se Fred le chiede. Dopo le
  correzioni serve una nuova ispezione Codex in sessione fresca (prevista dal metodo).
