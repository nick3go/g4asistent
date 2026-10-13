# G4 Asistent

Preprosta mobilna spletna aplikacija za osebne ocene. Registracija in prijava uporabljata samo **uporabniško ime in geslo**, brez Supabase Auth in brez e-poštnih naslovov.

## Nastavitev

1. V izbranem Supabase projektu odpri **SQL Editor** in zaženi celoten [schema.sql](schema.sql). Ustvari ločeni tabeli `g4_simple_users` in `g4_simple_grades` ter funkcijo `g4_simple_action`. Ni treba spreminjati nastavitev Authentication.
2. URL in javni Supabase ključ sta že v [config.js](config.js).
3. Na GitHubu odpri **Settings → Pages → Deploy from a branch → main → /(root)**. Stran bo na https://nick3go.github.io/g4asistent/.
4. Ustvari račun z imenom in geslom. Račun ostane prijavljen do zaprtja zavihka/seje brskalnika oziroma odjave.

## Opozorilo

To je **namenoma poenostavljena prijava**, ne ustreza zaščiti pomembnih osebnih podatkov. Geslo je shranjeno kot navadno besedilo v podatkovni bazi in v sessionStorage brskalnika. Ne uporabi gesla, ki ga uporabljaš kje drugje. Javni odjemalec kliče eno SQL funkcijo, ki preverja ime in geslo; neposreden dostop anonimnih uporabnikov do tabel je onemogočen. Ni e-poštne potrditve, obnove gesla, omejevanja poskusov prijave ali napredne zaščite.

Če si že izvedel starejšo različico schema.sql: novi objekti imajo drugačna imena in ne prepisujejo prejšnje tabele `g4_grades`. Stari podatki se ne prenesejo samodejno.

## Ocene in povprečja

Ocena vsebuje datum, številčno oceno od 1 do 5, vrsto (pisno, ustno, izdelek), predmet in lastnika. Podprti so `slo, mat, fiz, ang, nem, rač, rso, ele, esi, psim, fizm, zgom, špo`. Predmetno povprečje je aritmetično povprečje ocen pri tem predmetu. Skupno povprečje je aritmetična sredina **nezaokroženih predmetnih povprečij** predmetov z vsaj eno oceno. Prikaz je na dve decimalki.
