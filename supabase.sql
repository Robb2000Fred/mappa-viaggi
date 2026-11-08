-- Mappa Viaggi: una riga per "famiglia" (codice segreto), con dentro percorsi e preferiti.
-- Da incollare nell'SQL Editor di Supabase e premere Run (si può rilanciare: sostituisce le funzioni).

create table if not exists famiglie (
  codice text primary key,
  dati jsonb not null default '{}'::jsonb,
  aggiornato timestamptz not null default now()
);

-- Nessun accesso diretto alla tabella dal browser: si passa solo dalle funzioni sotto.
alter table famiglie enable row level security;
revoke all on table famiglie from anon, authenticated;

-- leggi(codice): restituisce i dati della famiglia (o {} se non esiste).
create or replace function leggi(codice text)
returns jsonb language plpgsql security definer set search_path = public as $$
#variable_conflict use_column
declare d jsonb;
begin
  if leggi.codice is null or length(leggi.codice) < 20 then raise exception 'codice non valido'; end if;
  select f.dati into d from famiglie f where f.codice = leggi.codice;
  return coalesce(d, '{}'::jsonb);
end $$;

-- unisci(a, b, del): unione di due elenchi di oggetti {id, mod, ...}: per ogni id vince il mod maggiore
-- (a parità: campo per campo name, at, date, icon, color, mode, distance, duration, lat, lon, pts, coords: stessa regola della pagina);
-- gli oggetti cancellati (del[id] >= mod) spariscono. Ordinati per "at" decrescente come nella pagina.
create or replace function unisci(a jsonb, b jsonb, del jsonb)
returns jsonb language sql immutable as $$
  select coalesce(jsonb_agg(x order by coalesce(x->>'at', '') desc), '[]'::jsonb) from (
    select distinct on (x->>'id') x from (
      select x from jsonb_array_elements(case when jsonb_typeof(a) = 'array' then a else '[]'::jsonb end) x
      union all
      select x from jsonb_array_elements(case when jsonb_typeof(b) = 'array' then b else '[]'::jsonb end) x
    ) t
    where jsonb_typeof(x) = 'object' and x ? 'id'
      and not (del ? (x->>'id') and (del->>(x->>'id')) >= coalesce(x->>'mod', ''))
    order by x->>'id', coalesce(x->>'mod', '') desc, coalesce(x->>'name', '') desc, coalesce(x->>'at', '') desc,
      coalesce(x->>'date', '') desc, coalesce(x->>'icon', '') desc, coalesce(x->>'color', '') desc, coalesce(x->>'mode', '') desc,
      coalesce(x->>'distance', '') desc, coalesce(x->>'duration', '') desc, coalesce(x->>'lat', '') desc, coalesce(x->>'lon', '') desc,
      coalesce(x->>'pts', '') desc, coalesce(x->>'coords', '') desc
  ) s;
$$;

-- scrivi(codice, dati): UNISCE i dati ricevuti con quelli già salvati (così due dispositivi non si sovrascrivono)
-- e restituisce il documento unito. Crea la riga la prima volta (massimo 50 famiglie, massimo 3 MB).
drop function if exists scrivi(text, jsonb);
create function scrivi(codice text, dati jsonb)
returns jsonb language plpgsql security definer set search_path = public as $$
#variable_conflict use_column
declare cur jsonb; del jsonb; merged jsonb;
begin
  if scrivi.codice is null or length(scrivi.codice) < 20 then raise exception 'codice non valido'; end if;
  if scrivi.dati is null or jsonb_typeof(scrivi.dati) <> 'object' then raise exception 'dati non validi'; end if;
  if pg_column_size(scrivi.dati) > 3000000 then raise exception 'troppi dati'; end if;

  -- Prima di leggere, blocco per questo codice: due scritture insieme (anche le prime due su un codice nuovo) vanno in fila.
  perform pg_advisory_xact_lock(hashtext(scrivi.codice));
  select f.dati into cur from famiglie f where f.codice = scrivi.codice for update;
  if cur is null then
    perform pg_advisory_xact_lock(4242);  -- il conteggio delle famiglie è atomico
    if (select count(*) from famiglie) >= 50 then raise exception 'limite famiglie raggiunto'; end if;
    cur := '{}'::jsonb;
  end if;

  -- cancellazioni: per ogni id vince la data maggiore
  select coalesce(jsonb_object_agg(k, to_jsonb(v)), '{}'::jsonb) into del from (
    select k, max(v) as v from (
      select key as k, value #>> '{}' as v from jsonb_each(case when jsonb_typeof(cur->'del') = 'object' then cur->'del' else '{}'::jsonb end)
      union all
      select key, value #>> '{}' from jsonb_each(case when jsonb_typeof(scrivi.dati->'del') = 'object' then scrivi.dati->'del' else '{}'::jsonb end)
    ) t group by k
  ) u;

  merged := jsonb_build_object(
    'v', 1,
    'routes', unisci(cur->'routes', scrivi.dati->'routes', del),
    'favs', unisci(cur->'favs', scrivi.dati->'favs', del),
    'del', del);
  if pg_column_size(merged) > 3000000 then raise exception 'troppi dati'; end if;

  insert into famiglie (codice, dati, aggiornato) values (scrivi.codice, merged, now())
  on conflict (codice) do update set dati = excluded.dati, aggiornato = now();
  return merged;
end $$;

revoke all on function leggi(text) from public;
revoke all on function unisci(jsonb, jsonb, jsonb) from public;
revoke all on function scrivi(text, jsonb) from public;
grant execute on function leggi(text) to anon;
grant execute on function scrivi(text, jsonb) to anon;
