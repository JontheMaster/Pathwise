-- Vereine, ihre Ansprechpersonen und Beratungsstellen — und der
-- Einschaetzungsspiegel wird endlich vereinsbezogen.
--
-- Bis hierher lagen die Vereinsangaben im App-Buendel: eine Aenderung hiess
-- neue APK fuer alle. Und zaehlwerte kannte keinen Verein, obwohl die
-- Auswertung "So haben die Trainerinnen und Trainer deines Vereins
-- entschieden" verspricht.
--
-- Ein Geraet erfaehrt seinen Verein ueber einen kurzen Code, den es einmal
-- eingibt. Der Code ist kein Login und kein Geheimnis — er ordnet zu, mehr
-- nicht. Wer ihn hat, sieht die Ansprechpersonen des Vereins; die stehen
-- ohnehin im Schutzkonzept.

-- ---------------------------------------------------------------------------
-- Vereine
-- ---------------------------------------------------------------------------

create table if not exists public.vereine (
  id          uuid primary key default gen_random_uuid(),
  code        text not null unique
                check (code = upper(code) and char_length(code) between 4 and 32),
  name        text not null check (char_length(name) between 1 and 120),
  aktiv       boolean not null default true,
  erstellt_am timestamptz not null default now()
);

create table if not exists public.ansprechpersonen (
  id          uuid primary key default gen_random_uuid(),
  verein_id   uuid not null references public.vereine(id) on delete cascade,
  name        text not null check (char_length(name) between 1 and 120),
  rolle       text not null check (char_length(rolle) between 1 and 120),
  kontakt     text not null check (char_length(kontakt) between 1 and 254),
  kontaktart  text not null check (kontaktart in ('mail', 'telefon')),
  reihenfolge smallint not null default 0
);

create index if not exists ansprechpersonen_verein_idx
  on public.ansprechpersonen (verein_id, reihenfolge);

-- verein_id null heisst "gilt fuer alle". So bleiben Hilfetelefon und Nummer
-- gegen Kummer zentral, ein Verein kann aber eine regionale Stelle ergaenzen.
create table if not exists public.beratungsstellen (
  id          uuid primary key default gen_random_uuid(),
  verein_id   uuid references public.vereine(id) on delete cascade,
  titel       text not null check (char_length(titel) between 1 and 120),
  zusatz      text not null check (char_length(zusatz) between 0 and 200),
  nummer      text not null check (char_length(nummer) between 1 and 40),
  reihenfolge smallint not null default 0
);

create index if not exists beratungsstellen_verein_idx
  on public.beratungsstellen (verein_id, reihenfolge);

alter table public.vereine enable row level security;
alter table public.ansprechpersonen enable row level security;
alter table public.beratungsstellen enable row level security;
-- Keine Policy fuer anon: die App kommt ausschliesslich ueber die Funktion
-- unten an die Daten und braucht dafuer den Code. Ohne ihn laesst sich weder
-- eine Vereinsliste noch eine Sammlung von Kontaktdaten abziehen.

-- ---------------------------------------------------------------------------
-- Abruf fuer die App
-- ---------------------------------------------------------------------------

-- Liefert Name, Ansprechpersonen und Beratungsstellen zu einem Code — oder
-- null, wenn es den Code nicht gibt.
create or replace function public.vereinsangaben(p_code text)
returns jsonb
language sql
stable
security definer
set search_path = public
as $$
  select jsonb_build_object(
    'id', v.id,
    'code', v.code,
    'name', v.name,
    'personen', (
      select coalesce(
        jsonb_agg(
          jsonb_build_object(
            'name', a.name,
            'rolle', a.rolle,
            'kontakt', a.kontakt,
            'kontaktart', a.kontaktart
          ) order by a.reihenfolge, a.name
        ),
        '[]'::jsonb
      )
      from public.ansprechpersonen a
      where a.verein_id = v.id
    ),
    'beratung', (
      select coalesce(
        jsonb_agg(
          jsonb_build_object(
            'titel', b.titel,
            'zusatz', b.zusatz,
            'nummer', b.nummer
          ) order by b.reihenfolge, b.titel
        ),
        '[]'::jsonb
      )
      from public.beratungsstellen b
      where b.verein_id is null or b.verein_id = v.id
    )
  )
  from public.vereine v
  where v.code = upper(btrim(p_code))
    and v.aktiv;
$$;

-- ---------------------------------------------------------------------------
-- Zaehlwerte je Verein
-- ---------------------------------------------------------------------------

-- Die bisherigen Zeilen stammen aus der Erprobung und haben keinen Verein.
delete from public.zaehlwerte;

alter table public.zaehlwerte
  add column if not exists verein_id uuid references public.vereine(id) on delete cascade;

-- Der alte Schluessel kannte keinen Verein.
alter table public.zaehlwerte drop constraint if exists zaehlwerte_pkey;
alter table public.zaehlwerte alter column verein_id set not null;
alter table public.zaehlwerte
  add constraint zaehlwerte_pkey
  primary key (verein_id, szenario_id, punkt_index, option_id);

-- "Genau drei Entscheidungspunkte" ist keine feste Groesse mehr, sobald
-- Szenarien bearbeitbar werden.
alter table public.zaehlwerte drop constraint if exists zaehlwerte_punkt_index_check;
alter table public.zaehlwerte
  add constraint zaehlwerte_punkt_index_check check (punkt_index between 0 and 49);

drop function if exists public.zaehlwert_erhoehen(text, smallint, text);
drop function if exists public.spiegel(text);

create or replace function public.zaehlwert_erhoehen(
  p_verein   uuid,
  p_szenario text,
  p_punkt    smallint,
  p_option   text
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
  if not exists (select 1 from public.vereine where id = p_verein and aktiv) then
    raise exception 'Verein unbekannt';
  end if;

  insert into public.zaehlwerte as z
    (verein_id, szenario_id, punkt_index, option_id, anzahl)
  values (p_verein, p_szenario, p_punkt, p_option, 1)
  on conflict (verein_id, szenario_id, punkt_index, option_id)
    do update set anzahl = z.anzahl + 1;
end;
$$;

create or replace function public.spiegel(p_verein uuid, p_szenario text)
returns table (punkt_index smallint, option_id text, anzahl integer)
language sql
stable
security definer
set search_path = public
as $$
  select z.punkt_index, z.option_id, z.anzahl
  from public.zaehlwerte z
  where z.verein_id = p_verein
    and z.szenario_id = p_szenario;
$$;

-- ---------------------------------------------------------------------------
-- Rueckmeldungen: woher kam sie, und ist sie erledigt
-- ---------------------------------------------------------------------------

alter table public.rueckmeldungen
  add column if not exists verein_id uuid references public.vereine(id) on delete set null;
alter table public.rueckmeldungen
  add column if not exists bearbeitet boolean not null default false;

-- ---------------------------------------------------------------------------
-- Rechte
-- ---------------------------------------------------------------------------

revoke all on function public.vereinsangaben(text) from public;
revoke all on function public.zaehlwert_erhoehen(uuid, text, smallint, text) from public;
revoke all on function public.spiegel(uuid, text) from public;

grant execute on function public.vereinsangaben(text) to anon, authenticated;
grant execute on function public.zaehlwert_erhoehen(uuid, text, smallint, text) to anon, authenticated;
grant execute on function public.spiegel(uuid, text) to anon, authenticated;
