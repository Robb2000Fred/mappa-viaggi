-- Mappa Viaggi: una riga per "famiglia" (codice segreto), con dentro percorsi e preferiti.
-- Da incollare una volta sola nell'SQL Editor di Supabase e premere Run.

create table if not exists famiglie (
  codice text primary key,
  dati jsonb not null default '{}'::jsonb,
  aggiornato timestamptz not null default now()
);

-- Nessun accesso diretto alla tabella dal browser: si passa solo dalle due funzioni sotto.
alter table famiglie enable row level security;
revoke all on table famiglie from anon, authenticated;

-- leggi(codice): restituisce i dati della famiglia (o {} se non esiste).
create or replace function leggi(codice text)
returns jsonb language plpgsql security definer set search_path = public as $$
declare d jsonb;
begin
  if codice is null or length(codice) < 20 then raise exception 'codice non valido'; end if;
  select f.dati into d from famiglie f where f.codice = leggi.codice;
  return coalesce(d, '{}'::jsonb);
end $$;

-- scrivi(codice, dati): salva i dati della famiglia (crea la riga la prima volta, massimo 20 famiglie, massimo 3 MB).
create or replace function scrivi(codice text, dati jsonb)
returns timestamptz language plpgsql security definer set search_path = public as $$
declare t timestamptz;
begin
  if codice is null or length(codice) < 20 then raise exception 'codice non valido'; end if;
  if pg_column_size(dati) > 3000000 then raise exception 'troppi dati'; end if;
  if not exists (select 1 from famiglie f where f.codice = scrivi.codice)
     and (select count(*) from famiglie) >= 20 then raise exception 'limite famiglie raggiunto'; end if;
  insert into famiglie (codice, dati, aggiornato) values (scrivi.codice, scrivi.dati, now())
  on conflict (codice) do update set dati = excluded.dati, aggiornato = now()
  returning aggiornato into t;
  return t;
end $$;

revoke all on function leggi(text) from public;
revoke all on function scrivi(text, jsonb) from public;
grant execute on function leggi(text) to anon;
grant execute on function scrivi(text, jsonb) to anon;
