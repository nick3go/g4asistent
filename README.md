# G4Asistent

Spletna redovalnica z imenom, geslom in poljubnim razredom (privzeto G4A). Ocene vsebujejo predmet, vrsto, datum, oceno, neobvezne procente ter povezavo do popravljene ocene. Vsak uporabnik vidi samo svoje ocene.

## Namestitev (od zacetka)

1. Odpri Supabase projekt → **SQL Editor → New query**.
2. **Enkrat** zaženi celotno datoteko [setup.sql](setup.sql). To je **edina potrebna SQL datoteka za novo namestitev**. Ustvari shemo `g4a_private`, tabeli `users` in `grades` ter funkcijo `public.g4a_api`. Projekt Timeline, njegova shema `timeline_private` in funkcija `timeline_api` ostanejo nedotaknjeni.
3. V [config.js](config.js) vnesi URL in **javni** Supabase publishable key. Ne objavljaj secret ali service_role ključa.
4. V GitHub **Settings → Pages** izberi **Deploy from a branch → main → /(root)** in odpri svojo domeno oziroma URL strani.
5. Registriraj uporabnika z imenom, geslom in razredom.

**Če je G4Asistent že nameščen in deluje, datoteke setup.sql NE izvajaj ponovno.** Ta datoteka je namenjena postavitvi nove aplikacije. Stare migracije so ohranjene v zgodovini Git in jih ni treba ponovno zaganjati. Obstoječa namestitev ostane nespremenjena.

## Varnost

Aplikacija uporablja namerno poenostavljen način prijave; gesla so v podatkovni bazi shranjena kot navadno besedilo ter med sejo v brskalnikovem `sessionStorage`. Ne uporabljaj gesel z drugih storitev. To ni primerno za občutljive podatke. Neposreden dostop anonimnih uporabnikov do tabel je onemogočen, namesto tega aplikacija kliče SQL funkcijo `g4a_api`.

## Povprečja in ocene

Ocena je od 1 do 5. Vrste so pisno, ustno in izdelek. Procenti so neobvezni. Ob vnosu jih JavaScript primerja z oceno: 1 (0–50), 2 (45–65), 3 (60–80), 4 (70–90), 5 (90–100). Strežnik preveri le interval 0–100; podrobnejša lestvica je namerno samo v odjemalcu.

Popravljena in prvotna ocena ostaneta obe vidni, pri predmetnem povprečju pa šteje samo boljša. Skupno povprečje je srednja vrednost nezaokroženih povprečij predmetov z ocenami; prikaz je na dve decimalki.

## Predmeti

`slo`, `mat`, `ang`, `nem`, `fiz`, `rač`, `rso`, `ele`, `esi`, `špo`, `fizm`, `psim`, `zgom`.
