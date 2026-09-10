-- Szenarien in der Datenbank — mit Entwürfen und Fassungen.
--
-- Bis hierher lagen die Szenarien in assets/szenarien.json: ein Tippfehler
-- hiess neue App-Fassung fuer alle. Jetzt holt die App sie beim Start; das
-- Buendel bleibt Rueckfallebene, wenn kein Netz da ist.
--
-- Drei Entscheidungen, die hier festgeschrieben werden:
--
-- 1. Ein Szenario liegt als *ein* jsonb, nicht in vier Tabellen. Die App
--    parst genau diese Form schon (assets/szenarien.json), das Dashboard
--    bearbeitet ein Szenario ohnehin als Ganzes, und eine Fassung ist so
--    eine einzige Zeile statt eines Baums von Zeilen.
--
-- 2. Wer ein Szenario angefangen hat, spielt es in der Fassung zu Ende, in
--    der er begonnen hat. Deshalb bleibt jede veroeffentlichte Fassung in
--    szenario_fassungen stehen und ist einzeln abrufbar. Sonst wechselte
--    mitten im Durchlauf die Leitfrage.
--
-- 3. Zaehlwerte gehoeren zu der Fassung der *Entscheidungspunkte*, in der
--    sie entstanden sind — nicht zum Szenario und nicht zur Fassungsnummer.
--    Ein korrigierter Tippfehler im Titel darf den Einschaetzungsspiegel
--    nicht leeren; eine geaenderte Handlungsoption muss ihn leeren, sonst
--    zeigt der Balken Prozente ueber einen Text, den so nie jemand gelesen
--    hat. Dazu dient die Signatur: ein Fingerabdruck ueber Leitfragen und
--    Handlungsoptionen, sonst nichts.

-- ---------------------------------------------------------------------------
-- Signatur der Entscheidungspunkte
-- ---------------------------------------------------------------------------

create or replace function public.szenario_signatur(p_inhalt jsonb)
returns text
language sql
immutable
as $$
  select md5(coalesce(
    (
      select string_agg(
               (p.wert ->> 'leitfrage') || '#' || coalesce(
                 (
                   select string_agg(
                            (o.wert ->> 'id') || '=' || (o.wert ->> 'text'),
                            ';' order by o.nr
                          )
                   from jsonb_array_elements(p.wert -> 'optionen')
                        with ordinality as o(wert, nr)
                 ),
                 ''
               ),
               '||' order by p.nr
             )
      from jsonb_array_elements(coalesce(p_inhalt -> 'punkte', '[]'::jsonb))
           with ordinality as p(wert, nr)
    ),
    ''
  ));
$$;

-- ---------------------------------------------------------------------------
-- Szenarien
-- ---------------------------------------------------------------------------

create table if not exists public.szenarien (
  id              text primary key
                    check (char_length(id) between 1 and 64),
  status          text not null default 'entwurf'
                    check (status in ('entwurf', 'veroeffentlicht')),
  reihenfolge     smallint not null default 0,

  -- Zaehlt nur hoch, wenn sich eine bereits veroeffentlichte Fassung aendert.
  fassung         integer not null default 1 check (fassung >= 1),

  -- Die Form aus assets/szenarien.json: id, titel, themenfeld, kurz, dauer,
  -- rahmen, vorgeschichte, ausgangssituation, punkte, merkmale.
  inhalt          jsonb not null,

  -- Wird vom Trigger gesetzt, nie von Hand.
  signatur        text not null default '',

  erstellt_am     timestamptz not null default now(),
  aktualisiert_am timestamptz not null default now(),

  -- Was die App zwingend braucht, um ein Szenario ueberhaupt zu zeigen.
  constraint szenarien_inhalt_form check (
    jsonb_typeof(inhalt -> 'punkte') = 'array'
    and jsonb_array_length(inhalt -> 'punkte') between 1 and 50
    and jsonb_typeof(inhalt -> 'merkmale') = 'array'
    and coalesce(inhalt ->> 'titel', '') <> ''
    and coalesce(inhalt ->> 'themenfeld', '') <> ''
  )
);

create index if not exists szenarien_veroeffentlicht_idx
  on public.szenarien (reihenfolge, id)
  where status = 'veroeffentlicht';

-- Jede veroeffentlichte Fassung bleibt abrufbar, damit ein angefangener
-- Durchlauf zu Ende gespielt werden kann.
create table if not exists public.szenario_fassungen (
  szenario_id        text not null references public.szenarien(id) on delete cascade,
  fassung            integer not null,
  inhalt             jsonb not null,
  signatur           text not null,
  veroeffentlicht_am timestamptz not null default now(),
  primary key (szenario_id, fassung)
);

alter table public.szenarien enable row level security;
alter table public.szenario_fassungen enable row level security;
-- Keine Policy fuer anon: die App liest ausschliesslich ueber die Funktionen
-- weiter unten. Entwuerfe bleiben so unsichtbar, auch wenn jemand den
-- Publishable Key aus dem Web-Bundle zieht.

-- ---------------------------------------------------------------------------
-- Fassungen pflegen
-- ---------------------------------------------------------------------------

create or replace function public.szenario_pflegen()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  new.signatur := public.szenario_signatur(new.inhalt);
  new.aktualisiert_am := now();

  -- Die id im jsonb und die id der Zeile muessen dasselbe sein — die App
  -- liest die id aus dem Inhalt.
  new.inhalt := new.inhalt || jsonb_build_object('id', new.id);

  if tg_op = 'UPDATE' then
    if old.status = 'veroeffentlicht'
       and new.status = 'veroeffentlicht'
       and new.inhalt is distinct from old.inhalt then
      -- Aenderung an etwas, das schon draussen ist: neue Fassung.
      new.fassung := old.fassung + 1;
    else
      -- Entwuerfe und das erste Veroeffentlichen bleiben bei ihrer Nummer.
      new.fassung := old.fassung;
    end if;
  end if;

  return new;
end;
$$;

drop trigger if exists szenarien_pflegen on public.szenarien;
create trigger szenarien_pflegen
  before insert or update on public.szenarien
  for each row execute function public.szenario_pflegen();

create or replace function public.szenario_fassung_sichern()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  if new.status = 'veroeffentlicht' then
    insert into public.szenario_fassungen
      (szenario_id, fassung, inhalt, signatur)
    values (new.id, new.fassung, new.inhalt, new.signatur)
    on conflict (szenario_id, fassung) do update
      set inhalt = excluded.inhalt,
          signatur = excluded.signatur;
  end if;
  return null;
end;
$$;

drop trigger if exists szenarien_fassung_sichern on public.szenarien;
create trigger szenarien_fassung_sichern
  after insert or update on public.szenarien
  for each row execute function public.szenario_fassung_sichern();

-- ---------------------------------------------------------------------------
-- Abruf fuer die App
-- ---------------------------------------------------------------------------

-- Alle veroeffentlichten Szenarien in ihrer aktuellen Fassung.
create or replace function public.szenarien_aktuell()
returns jsonb
language sql
stable
security definer
set search_path = public
as $$
  select coalesce(
    jsonb_agg(
      s.inhalt || jsonb_build_object('fassung', s.fassung, 'signatur', s.signatur)
      order by s.reihenfolge, s.id
    ),
    '[]'::jsonb
  )
  from public.szenarien s
  where s.status = 'veroeffentlicht';
$$;

-- Eine bestimmte Fassung — fuer angefangene Durchlaeufe.
create or replace function public.szenario_fassung(p_id text, p_fassung integer)
returns jsonb
language sql
stable
security definer
set search_path = public
as $$
  select f.inhalt || jsonb_build_object('fassung', f.fassung, 'signatur', f.signatur)
  from public.szenario_fassungen f
  where f.szenario_id = p_id
    and f.fassung = p_fassung;
$$;

-- ---------------------------------------------------------------------------
-- Zaehlwerte an die Signatur binden
-- ---------------------------------------------------------------------------

-- Die bisherigen Zeilen stammen aus der Erprobung und kennen keine Signatur.
delete from public.zaehlwerte;

alter table public.zaehlwerte
  add column if not exists signatur text not null default '';

alter table public.zaehlwerte drop constraint if exists zaehlwerte_pkey;
alter table public.zaehlwerte
  add constraint zaehlwerte_pkey
  primary key (verein_id, szenario_id, signatur, punkt_index, option_id);

drop function if exists public.zaehlwert_erhoehen(uuid, text, smallint, text);
drop function if exists public.spiegel(uuid, text);

create or replace function public.zaehlwert_erhoehen(
  p_verein    uuid,
  p_szenario  text,
  p_signatur  text,
  p_punkt     smallint,
  p_option    text
) returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if p_punkt < 0 or p_punkt > 49 then
    raise exception 'punkt_index ausserhalb 0..49';
  end if;
  if p_option not in ('a', 'b', 'c') then
    raise exception 'option_id muss a, b oder c sein';
  end if;
  if length(p_szenario) = 0 or length(p_szenario) > 64 then
    raise exception 'szenario_id ungueltig';
  end if;
  if length(p_signatur) <> 32 then
    raise exception 'signatur ungueltig';
  end if;
  if not exists (select 1 from public.vereine where id = p_verein and aktiv) then
    raise exception 'Verein unbekannt';
  end if;

  insert into public.zaehlwerte as z
    (verein_id, szenario_id, signatur, punkt_index, option_id, anzahl)
  values (p_verein, p_szenario, p_signatur, p_punkt, p_option, 1)
  on conflict (verein_id, szenario_id, signatur, punkt_index, option_id)
    do update set anzahl = z.anzahl + 1;
end;
$$;

create or replace function public.spiegel(
  p_verein   uuid,
  p_szenario text,
  p_signatur text
)
returns table (punkt_index smallint, option_id text, anzahl integer)
language sql
stable
security definer
set search_path = public
as $$
  select z.punkt_index, z.option_id, z.anzahl
  from public.zaehlwerte z
  where z.verein_id = p_verein
    and z.szenario_id = p_szenario
    and z.signatur = p_signatur;
$$;

-- ---------------------------------------------------------------------------
-- Rechte
-- ---------------------------------------------------------------------------

revoke all on function public.szenarien_aktuell() from public;
revoke all on function public.szenario_fassung(text, integer) from public;
revoke all on function public.zaehlwert_erhoehen(uuid, text, text, smallint, text) from public;
revoke all on function public.spiegel(uuid, text, text) from public;

grant execute on function public.szenarien_aktuell() to anon, authenticated;
grant execute on function public.szenario_fassung(text, integer) to anon, authenticated;
grant execute on function public.zaehlwert_erhoehen(uuid, text, text, smallint, text) to anon, authenticated;
grant execute on function public.spiegel(uuid, text, text) to anon, authenticated;
