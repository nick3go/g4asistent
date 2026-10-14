# G4Asistent

Spletna redovalnica z imenom, geslom in poljubnim razredom (privzeto G4A). Ocene vsebujejo predmet, vrsto, datum, oceno, neobvezne procente ter povezavo do popravljene ocene. Vsak uporabnik vidi samo svoje ocene.

## Namestitev (od zacetka)

1. Odpri Supabase projekt → **SQL Editor → New query**.
2. **Enkrat** zaženi celotno datoteko [setup.sql](setup.sql). To je **edina potrebna SQL datoteka za novo namestitev**. Ustvari shemo `g4a_private`, tabeli `users` in `grades` ter funkcijo `public.g4a_api`. Projekt Timeline, njegova shema `timeline_private` in funkcija `timeline_api` ostanejo nedotaknjeni.
3. V [config.js](config.js) vnesi URL in **javni** Supabase publishable key. Ne objavljaj secret ali service_role ključa.
4. V GitHub **Settings → Pages** izberi **Deploy from a branch → main → /(root)** in odpri svojo domeno oziroma URL strani.
5. Registriraj uporabnika z imenom, geslom in razredom.

**Za obstoječo namestitev** lahko ponovno izvedeš \`setup.sql\`, ko je dodana nova funkcionalnost, na primer razredna statistika. Skripta je pripravljena tako, da ohrani obstoječe podatke. Pred posegi v produkcijski projekt je priporočljiva varnostna kopija.

## Varnost

Aplikacija uporablja namerno poenostavljen način prijave; gesla so v podatkovni bazi shranjena kot navadno besedilo ter med sejo v brskalnikovem `sessionStorage`. Ne uporabljaj gesel z drugih storitev. To ni primerno za občutljive podatke. Neposreden dostop anonimnih uporabnikov do tabel je onemogočen, namesto tega aplikacija kliče SQL funkcijo `g4a_api`.

## Povprečja in ocene

Ocena je od 1 do 5. Vrste so pisno, ustno in izdelek. Procenti so neobvezni. Ob vnosu jih JavaScript primerja z oceno: 1 (0–50), 2 (45–65), 3 (60–80), 4 (70–90), 5 (90–100). Strežnik preveri le interval 0–100; podrobnejša lestvica je namerno samo v odjemalcu.

Popravljena in prvotna ocena ostaneta obe vidni, pri predmetnem povprečju pa šteje samo boljša. Skupno povprečje je srednja vrednost nezaokroženih povprečij predmetov z ocenami; prikaz je na dve decimalki.

## Predmeti

`slo`, `mat`, `ang`, `nem`, `fiz`, `rač`, `rso`, `ele`, `esi`, `špo`, `fizm`, `psim`, `zgom`.

## Statistika razreda

Podstran `/statistika/` prikazuje statistiko **pisnih** ocen (vrsta `pisno`) vseh uporabnikov, ki imajo enako vrednost polja `class_name` kot prijavljeni uporabnik. Razred je poljubno besedilo, zato se mora pri vseh dijakih ujemati (vključno z velikimi in malimi črkami). Brez prijave statistika ni dostopna. Na strani se ne prikazujejo imena uporabnikov.

Testi se združujejo po predmetu in datumih: od prvega datuma testa do zadnjega sta lahko največ **dva koledarska dneva razlike** (trije zaporedni dnevi). Vrstni red ocen in njihovih datumov je nepomemben; če isti dijak za isti predmet vnese več pisnih ocen v istem obdobju, se trenutno šteje vsak zapis. Popravljene ocene so iz statistike izključene, vključene so prvotne pisne ocene. Za vsak test se izračunajo povprečje, število ocen 1–5 in povprečni odstotek, kadar obstaja.

**Nadgradnja obstoječe podatkovne baze:** po dodajanju statistike lahko v SQL Editorju ponovno zaženeš [setup.sql](setup.sql). Skripta uporablja `CREATE IF NOT EXISTS` in `CREATE OR REPLACE FUNCTION`, zato obstoječih računov in ocen ne izbriše. Posodobila bo `g4a_api` z dejanjem `class_stats` in se ne dotakne sheme `timeline_private`. Za novo namestitev zadošča en zagon iste datoteke.

## Prihajajoča ocenjevanja in administracija

- `/ocenjevanja/`: prijavljeni uporabnik vidi samo ocenjevanja svojega razreda. Dan po datumu ocenjevanja se postavka premakne med pretekla ocenjevanja. Sedmi dan po datumu izgine iz prikaza in jo strežnik izbriše ob prvem naslednjem dostopu; če je na Supabase omogočen **pg_cron**, jo vsak dan odstrani tudi urnik ob 00:10 UTC.
- `/admin/`: vpis novih ocenjevanj (predmet, vrsta: pisno/ustno/izdelek, datum in razred), pregled in brisanje.

### Nastavitev na obstoječem projektu

1. Znova zaženi **[setup.sql](setup.sql)** v Supabase SQL Editorju. Ohrani vse obstoječe podatke G4Asistenta in ne spreminja Timeline.
2. V Supabase SQL Editorju **zasebno** nastavi geslo (zamenjaj `TVOJE_NOVO_GESLO`):

   ```sql
   insert into g4a_private.admin_settings(singleton,password)
   values (true, 'TVOJE_NOVO_GESLO')
   on conflict (singleton) do update set password=excluded.password;
   ```

   Poizvedbe z resničnim geslom ne objavljaj na GitHubu. Geslo se primerja kot navaden niz, brez dodatnih razširitev.
3. Za samodejno čiščenje neodvisno od obiskov v Supabase pod **Database → Extensions** omogoči `pg_cron`, nato znova zaženi `setup.sql`. Če razširitve ne omogočiš, zastareli zapisi vseeno izginejo s strani in se izbrišejo ob naslednjem dostopu, ne pa nujno točno po sedmih dneh.

**Opozorilo:** ta poenostavljena prijava ni ustrezna za zelo občutljive podatke; dijaki lahko vidijo razredna ocenjevanja samo ob pravilnem uporabniškem imenu in geslu. Geslo je v zasebni tabeli Supabase in ni več v aktualni javni kodi. Staro geslo je že bilo objavljeno v zgodovini Git, zato izberi novega. Ta prijava še vedno nima zaščite pred ugibanjem gesel.
