# Mappa Viaggi: piano

Pagina sola su GitHub Pages (https://robb2000fred.github.io/mappa-viaggi/), senza login.
Percorsi e preferiti salvati nel browser e, se attiva, sincronizzati tra i dispositivi di Fred con Supabase.

## Sicurezza e dati

**Modello delle minacce.** Chi potrebbe attaccare: un curioso che trova il link del sito (pubblico), uno spammer
che chiama le funzioni del database a caso. Cosa vuole: leggere o rovinare i percorsi, riempire il database.
Cosa si perde al massimo: l'itinerario di un viaggio (nessun dato di altre persone, nessun pagamento, nessuna
password). Il sito stesso non contiene dati: solo la pagina.

**Le 5 domande, per ogni funzione che tocca dati.**

Funzioni: `leggi(codice)` e `scrivi(codice, dati)` su Supabase, chiamate dal browser con la chiave "anon" (pubblica per progetto).

1. *Chi può chiamarle senza passare dall'interfaccia?* Chiunque abbia la chiave anon (è nella pagina, quindi
   chiunque). Senza il codice famiglia però `leggi` restituisce `{}` e `scrivi` crea una riga vuota a sé:
   non si arriva ai dati di Fred. La tabella non è leggibile direttamente (RLS attiva, nessuna policy, privilegi tolti).
2. *Se qualcuno cambia un numero o un id?* L'unico id è il codice famiglia: 20+ caratteri casuali
   (circa 100 bit), non indovinabile per tentativi. Un codice sbagliato apre una famiglia vuota.
3. *Se la chiama un milione di volte?* Supabase limita le richieste del piano gratuito; in più `scrivi` crea al
   massimo 20 famiglie e rifiuta dati sopra 3 MB, quindi lo spam non riempie il database. Nel peggiore dei casi
   il progetto gratuito si ferma per un po': i dati restano nel browser dei dispositivi.
4. *Se una chiave finisce su GitHub?* La chiave anon è pensata per stare nella pagina: da sola non legge nulla
   (vedi 1). La password del database e la "service role key" non entrano mai nel codice né in git.
   Il codice famiglia non va mai scritto nel repository.
5. *Chi paga?* Nessuno: piano gratuito Supabase senza carta, account a nome di Fred (i dati sono suoi).
   Tetto di spesa: non esiste spesa.

**OWASP Top 10, stato.** Controllo accessi: coperto dal codice segreto + funzioni security definer (non c'è
login per scelta). Configurazione: RLS attiva, tabella non esposta. Catena di fornitura: Leaflet 1.9.4 servito in
locale, font in locale, nessuna libreria da CDN. Crittografia: https di GitHub Pages e Supabase. Iniezione: le funzioni
usano parametri, i dati sono jsonb; nella pagina ogni testo passa da `esc()`. Autenticazione: assente per scelta
(il codice famiglia fa da chiave condivisa). Integrità: ultima scrittura vince, per oggetto, con cancellazioni
tracciate. Registri/avvisi: NON coperto (nessun log oltre a quelli di Supabase). Gestione errori: messaggi generici.

**Non fatto, dichiarato.** Revisione indipendente con claudex-loop: non eseguita (Codex non disponibile in questa
sessione). Prova con lettore di schermo: non fatta. Prova di carico: non fatta.
