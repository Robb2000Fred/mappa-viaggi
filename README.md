# Mappa Viaggi

La mia mappa per i viaggi: una pagina sola, senza account. Online su https://robb2000fred.github.io/mappa-viaggi/

## Cosa fa

- **Tappe con un tocco**: tocchi la mappa e scegli "Tappa A", "★ Preferito" o ✕ per annullare; il tocco dopo propone B, poi C… Toccando una lettera nella barra la sposti.
- **Cerca** (in alto): suggerimenti mentre scrivi (Photon), con Nominatim come riserva; dal risultato fai una tappa o un preferito.
- **Percorsi**: a piedi, in bici o in auto, con tracciato, distanza e tempo (OSRM). Nome, salvataggio, riapertura. I percorsi salvati restano disegnati sulla mappa con il nome sulla A. "Collega" mette un giorno (es. 16 nov) accanto al nome. "Copia link" dà un indirizzo che riapre quel percorso su qualsiasi dispositivo.
- **Preferiti**: posti con nome, icona (hotel, bus, barca, spiaggia…) e colore, sempre visibili sulla mappa.
- **Dove sono** (GPS, con la precisione indicata) e **Satellite / Mappa**: bottoni sulla mappa.
- **Telefono**: mappa a tutto schermo, barra fissa in basso con le lettere, il +, la ricerca e il menu; si installa sulla schermata Home.

## Dove stanno i dati

- Percorsi e preferiti vivono nel browser del dispositivo (localStorage).
- Con un **codice famiglia** (sezione "Codice famiglia" nel pannello) i dispositivi si sincronizzano tramite Supabase:
  crei il codice su uno, lo incolli sugli altri. Ogni modifica viene unita per oggetto (vince l'ultima modifica,
  le cancellazioni sono ricordate), anche se due dispositivi salvano insieme. Chi conosce il codice vede e cambia i tuoi dati: non va pubblicato.
- **Scollega** toglie il codice da quel dispositivo: i dati locali restano, non si sincronizzano più.
- Un **link condiviso** (`#r=…`, `#f=…`) porta solo quel percorso o quel preferito: chi lo apre lo vede e può salvarlo nel proprio browser; non entra nella tua famiglia.

## Senza internet

- La pagina si apre anche offline (service worker) con percorsi e preferiti.
- I pezzi di mappa che hai già guardato online restano salvati: per avere una zona pronta offline, scorrila e ingrandiscila una volta con internet. Non c'è un download in blocco: le regole di OpenStreetMap lo vietano.
- Offline la mappa è quella normale (il satellite non viene salvato). Cercare e calcolare percorsi nuovi richiede la rete.

## Servizi e sicurezza

Servizi usati: mappe OpenStreetMap, foto satellitari Esri, ricerca Photon (komoot) e Nominatim, percorsi OSRM (routing.openstreetmap.de), sincronizzazione Supabase (piano gratuito, account di Fred).
Il font Poppins e Leaflet 1.9.4 sono serviti da qui (`fonts/`, `vendor/`): nessuna libreria da siti esterni.
La chiave Supabase nella pagina è quella pubblica ("publishable"): da sola non legge nulla, la tabella non è esposta (RLS) e si passa solo dalle funzioni `leggi` e `scrivi` (`supabase.sql`). Piano, prove e revisione indipendente: `PLAN.md`, `RAPPORTO-REVISIONE.md`.

Online: pubblicata con GitHub Pages da questa cartella.
