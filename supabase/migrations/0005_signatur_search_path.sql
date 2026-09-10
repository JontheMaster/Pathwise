-- Nachtrag zu 0003: szenario_signatur bekommt einen festen search_path.
--
-- Der Supabase-Advisor (function_search_path_mutable) hat es gemeldet. Die
-- Funktion haengt an einem Trigger auf public.szenarien und entscheidet, an
-- welchen Zaehlwerten der Einschaetzungsspiegel haengt. Ohne festen
-- search_path bestimmt der Aufrufer mit, welche Funktionen darin gelten.
-- Hier benutzt sie zwar nur pg_catalog, aber die Regel gilt unabhaengig davon.
--
-- Die uebrigen Advisor-Hinweise bleiben absichtlich stehen:
--   rls_enabled_no_policy — genau so gewollt. Die Tabellen sind fuer anon zu,
--     der einzige Weg hinein sind die Funktionen.
--   anon/authenticated_security_definer_function_executable — das sind diese
--     Funktionen: die API der App. Jede prueft ihre Argumente selbst.

create or replace function public.szenario_signatur(p_inhalt jsonb)
returns text
language sql
immutable
set search_path = pg_catalog
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
