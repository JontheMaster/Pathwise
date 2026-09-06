-- Pathwise — Backend nach DESIGN.md 8.
--
-- Zwei Dinge gehen ueberhaupt ins Netz:
--   1. je Entscheidungspunkt und Handlungsoption ein Zaehlwert,
--   2. freiwillige Rueckmeldungen aus dem Rueckmeldungs-Sheet (S8).
-- Kein Konto, keine Geraetekennung, keine Sitzungs-ID, kein Personenbezug.
--
-- Der Datenbank-Linter meldet zu diesem Schema drei Punkte. Alle drei sind so
-- gewollt und duerfen nicht "repariert" werden:
--   * rls_enabled_no_policy auf zaehlwerte — genau der Zweck: kein Direktzugriff,
--     gearbeitet wird nur ueber die beiden Funktionen.
--   * anon/authenticated_security_definer_function_executable — die App hat
--     keine Anmeldung (DESIGN.md 1), anon muss zaehlen und lesen duerfen. Die
--     Funktionen pruefen ihre Argumente und koennen nur inkrementieren.

-- ---------------------------------------------------------------------------
-- Zaehlwerte
-- ---------------------------------------------------------------------------

-- Bewusst ohne Zeitstempel: aus Zeitpunkten liessen sich Sitzungen
-- rekonstruieren, und genau das schliesst DESIGN.md 8 aus.
create table if not exists public.zaehlwerte (
  szenario_id  text     not null,
  punkt_index  smallint not null check (punkt_index between 0 and 2),
  option_id    text     not null check (option_id in ('a', 'b', 'c')),
  anzahl       integer  not null default 0 check (anzahl >= 0),
  primary key (szenario_id, punkt_index, option_id)
);

alter table public.zaehlwerte enable row level security;
-- Keine Policy: der Direktzugriff ueber die REST-API ist damit gesperrt.
-- Gearbeitet wird ausschliesslich ueber die beiden Funktionen unten.

-- Erhoeht genau um eins. Als security definer, damit Clients keine beliebigen
-- Zaehlstaende setzen koennen — sie koennen nur zaehlen.
create or replace function public.zaehlwert_erhoehen(
  p_szenario text,
  p_punkt    smallint,
  p_option   text
) returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if p_punkt < 0 or p_punkt > 2 then
    raise exception 'punkt_index ausserhalb 0..2';
  end if;
  if p_option not in ('a', 'b', 'c') then
    raise exception 'option_id muss a, b oder c sein';
  end if;
  if length(p_szenario) = 0 or length(p_szenario) > 64 then
    raise exception 'szenario_id ungueltig';
  end if;

  insert into public.zaehlwerte as z (szenario_id, punkt_index, option_id, anzahl)
  values (p_szenario, p_punkt, p_option, 1)
  on conflict (szenario_id, punkt_index, option_id)
    do update set anzahl = z.anzahl + 1;
end;
$$;

-- Liefert die Zaehlwerte eines Szenarios. Prozentanteile und die Schwelle fuer
-- "zu wenige Einschaetzungen" rechnet die App (DESIGN.md 4.10).
create or replace function public.spiegel(p_szenario text)
returns table (punkt_index smallint, option_id text, anzahl integer)
language sql
stable
security definer
set search_path = public
as $$
  select z.punkt_index, z.option_id, z.anzahl
  from public.zaehlwerte z
  where z.szenario_id = p_szenario;
$$;

-- ---------------------------------------------------------------------------
-- Rueckmeldungen (S8)
-- ---------------------------------------------------------------------------

-- Hier ist ein Zeitstempel richtig: die Rueckmeldung wird von Hand bearbeitet,
-- der Absender weiss davon und gibt sie freiwillig ab.
create table if not exists public.rueckmeldungen (
  id          uuid primary key default gen_random_uuid(),
  art         text not null check (art in ('feedback', 'szenario')),
  text        text not null check (char_length(text) between 1 and 4000),
  email       text check (email is null or char_length(email) <= 254),
  erstellt_am timestamptz not null default now()
);

alter table public.rueckmeldungen enable row level security;

drop policy if exists "anon darf einsenden" on public.rueckmeldungen;
create policy "anon darf einsenden"
  on public.rueckmeldungen
  for insert
  to anon
  with check (true);
-- Kein select, update oder delete: ueber die API ist nichts davon lesbar.

-- ---------------------------------------------------------------------------
-- Rechte
-- ---------------------------------------------------------------------------

revoke all on function public.zaehlwert_erhoehen(text, smallint, text) from public;
revoke all on function public.spiegel(text) from public;

grant execute on function public.zaehlwert_erhoehen(text, smallint, text) to anon, authenticated;
grant execute on function public.spiegel(text) to anon, authenticated;
