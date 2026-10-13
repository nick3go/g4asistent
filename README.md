# G4 Asistent

Preprosta, odzivna spletna redovalnica: ločeni računi, vnos, urejanje in brisanje ocen, povprečje po predmetih in skupno povprečje **nezaokroženih povprečij vseh predmetov z ocenami**. Neocenjeni predmeti se v skupno povprečje ne štejejo. Prikaz na dve decimalki.

## Nastavitev (Supabase + GitHub Pages)

1. Odpri enega svojih **obstoječih Supabase projektov**. V **SQL Editor** prilepi in zaženi [schema.sql](schema.sql). Skripta ustvari samo tabelo `public.g4_grades`, zato ne posega v obstoječe tabele.
2. V **Authentication → Providers → Email** omogoči prijavo prek e-pošte, **izključi Confirm email**. To je potrebno, ker aplikacija pod pokrovom uporablja rezervirani navidezni naslov uporabniškega imena (npr. `nick@g4asistent.example.com`). Ni potrebe po uporabnikovem pravem e-naslovu.
3. V **Project Settings / Connect → API** poišči **Project URL** in **publishable key** (ali legacy `anon` key). Vnesi ju v [config.js](config.js). Ta ključ sme biti javen. **Service role/secret key nikoli ne objavljaj.**
4. V GitHub repozitoriju v **Settings → Pages → Build and deployment** izberi **Deploy from a branch**, `main`, `/(root)` in shrani. Po objavi bo stran na `https://nick3go.github.io/g4asistent/`.
5. Ustvari uporabniško ime (3–24 znakov: male/velike ASCII črke, številke, pika, podčrtaj, vezaj) ter geslo vsaj 6 znakov.

## Pomembno o prijavi

Supabase Auth podpira prijavo prek e-pošte/gesla, zato aplikacija uporabniško ime pretvori v determinističen tehnični e-naslov v domeni `g4asistent.example.com`. Uporabnik vidi samo ime in geslo, dejanske e-pošte ne potrebuje. **Ni možnosti ponastavitve pozabljenega gesla po e-pošti.** Gesla preverja in hrani Supabase Auth, ne naša tabela. Po želji je mogoče kasneje dodati pravo prijavo po e-pošti.

Izklop potrditve e-pošte velja za **celoten izbrani Supabase projekt** (tudi druge aplikacije, če uporabljajo njegov Auth). Zato je najbolje izbrati projekt, katerega druga aplikacija nima zahteve po e-poštni potrditvi. Izklop potrditve pomeni tudi manj zaščite pred samodejnim ustvarjanjem računov; po potrebi omeji registracijo/rate limit ali uporabi pravi e-naslov.

## Varnost

RLS za vsako branje, vnos, popravljanje in brisanje preveri `owner_id = auth.uid()`. Ni dostopa do ocen drugih uporabnikov, tudi če kdo neposredno pokliče API. `anon` nima dovoljenj nad tabelo. Pred javno uporabo preveri RLS v Supabase dashboardu z dvema testnima računoma.

## Lokalni zagon

Odpri `index.html` prek lokalnega HTTP strežnika, npr. `python3 -m http.server 8000`, in obišči `http://localhost:8000`. Potrebna je povezava z internetom za Supabase in `supabase-js` CDN.

## Predmeti

`slo`, `mat`, `fiz`, `ang`, `nem`, `rač`, `rso`, `ele`, `esi`, `psim`, `fizm`, `zgom`, `špo`.

## Matematično pravilo

Vsak predmet: aritmetična sredina vseh njegovih ocen, brez uteži. Skupno: aritmetična sredina **povprečij** ocenjenih predmetov, tako da vsak predmet šteje enako ne glede na število ocen. Vmesna povprečja niso zaokrožena, zaokroži se samo prikaz.
