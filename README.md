# G4 Asistent

Spletna aplikacija za beleženje ocen s prijavo z imenom in geslom, brez Supabase Auth.

## Namestitev – skupni Supabase projekt s Timeline

**Pomembno:** zaženi samo [g4a-private.sql](g4a-private.sql), NE stare datoteke `schema.sql`. Nova SQL skripta ustvari lastno shemo `g4a_private` s tabelama `users` in `grades`, ter funkcijo `public.g4a_api()`. Ne uporablja in ne spreminja sheme `timeline_private`, funkcije `timeline_api` ali stare tabele `public.g4_grades`.

1. V projektu `ngtkrtabbxrwduleenwn` odpri **Supabase → SQL Editor → New query**.
2. Kopiraj in izvedi vsebino [g4a-private.sql](g4a-private.sql).
3. Preveri, da je skripta uspešna; nato omogoči GitHub Pages: **Settings → Pages → Deploy from branch → main → /(root)**.
4. Odpri https://nick3go.github.io/g4asistent/ in ustvari testni račun.

URL in javni ključ sta že nastavljena v `config.js`. V Supabase Authentication ni treba nič spreminjati.

### Preverjanje brez sprememb

```sql
select table_schema,table_name from information_schema.tables
where table_schema in ('timeline_private','g4a_private','public')
order by table_schema,table_name;
```

V `timeline_private` morata ostati `events` in `settings`; v `g4a_private` se pojavita `users` in `grades`. V `public` se ohranijo obstoječe tabele.

### Obstoječi podatki

Če si izvedel samo **prvo** G4A skripto, obstaja `public.g4_grades`, ki je nova aplikacija ne uporablja. Namenoma je ne brišemo. Če si že ustvaril račune in ocene s prehodno `g4_simple_action`, se ti ne prenesejo samodejno; za migracijo teh podatkov pripravi ločen pregled in kopiranje, preden karkoli odstraniš.

### Varnost in omejitve

Za manj pomembne šolske podatke uporablja aplikacija preprosto primerjavo uporabniškega imena in gesla. Gesla so v trenutni poenostavljeni izvedbi **shranjena v navadnem besedilu** in začasno v `sessionStorage`. **Ne uporabljaj gesel, ki jih uporabljaš drugje.** Neposreden anonimni dostop do tabel je prepovedan; vse operacije tečejo prek `g4a_api` in preverijo uporabniško ime/geslo. To ni nadomestilo za pravi avtentikacijski sistem in ni primerno za občutljive osebne podatke.

### Povprečja

Podprti so predmeti `slo, mat, fiz, ang, nem, rač, rso, ele, esi, psim, fizm, zgom, špo`. Ocene so od 1 do 5, vrste so pisno, ustno in izdelek. Skupno povprečje je povprečje nezaokroženih povprečij **predmetov z ocenami**; prikaz je na dve decimalki.

## Nadgradnja v2 (procenti in popravljene ocene)

Če imaš G4Asistent že povezan s Supabase, v SQL Editorju projekta izvedi **samo [g4a-upgrade-v2.sql](g4a-upgrade-v2.sql)**. Skripta v `g4a_private.grades` doda stolpca `percent` in `correction_of`, prilagodi funkcijo `public.g4a_api` in ohrani vse obstoječe uporabnike ter ocene. Timeline uporablja drugo shemo, zato ga ta migracija ne spreminja.

Procenti so neobvezni (0–100). Pri popravljanju izberi obstoječo oceno iz istega predmeta in dodaj novo; prvotna in popravljena ostaneta vidni. Za povprečje šteje večja od obeh. Vsako izvirno oceno je mogoče popraviti največ enkrat. Negativne ocene, ki so bile popravljene na 2 ali več, niso navedene med »Za popravit«. Tudi če je bil popravni poskus slabši, za povprečje ostane boljša ocena.

Prikaz predmetov vključuje samo tiste z ocenami. Vrstni red: slo, mat, ang, nem, fiz, rač, rso, ele, esi, špo, fizm, psim, zgom. Kartični in kompaktni pogled uporabljata iste podatke; gumb za urejanje in brisanje se pokaže po kliku na oceno.
