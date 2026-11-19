# Budget Tara x Mattel

Aplikasi pribadi Tara & Mattel: beranda bisnis (kanban + income), beranda household
(salary, expense, saving), pengeluaran bulanan (rutin & miscellaneous), tabungan & pocket
(persentase atau nominal), kalender kegiatan, to-do, link penting, dan Berdua.

- **Frontend:** satu halaman statis di `public/` (tanpa build step)
- **Data & login:** Supabase Free (organisasi "Tara x Mattel", project `budget-taraxmattel`)
  — tabel `docs` + `members`, Row Level Security, realtime, login lewat link email
- **Hosting:** Cloudflare Workers static assets (gratis) → `budget.taraxmattel.workers.dev`

## Struktur

```
public/
  index.html          aplikasi
  config.js           URL + publishable key Supabase
  vendor/supabase.js  supabase-js v2 (UMD, disimpan lokal)
  _headers            header keamanan
supabase/migrations/  skema, RLS, data awal 25 pos rutin
wrangler.jsonc        konfigurasi Cloudflare Workers
```

## Siapa yang bisa masuk

Hanya email di tabel `public.members` (Supabase → SQL Editor):

```sql
insert into public.members (email, who) values
  ('email-tara@contoh.com', 'a'),
  ('email-mattel@contoh.com', 'b');
```

`who` = `a` untuk Tara, `b` untuk Mattel. Nama tampil bisa diubah di menu Pengaturan.

## Pengaturan Supabase Auth (sekali saja)

Authentication → URL Configuration:
- **Site URL:** alamat aplikasi di Cloudflare, mis. `https://budget.taraxmattel.workers.dev`
- **Redirect URLs:** alamat yang sama + `/**`

## Deploy ke Cloudflare

Cloudflare dashboard → Workers & Pages → Create → Import a repository → pilih
`taraxmattel/budget-taraxmattel`. Build command kosong, deploy command `npx wrangler deploy`.
Setiap push ke `main` otomatis terbit.

## Catatan

- Project Supabase Free dijeda bila tidak dibuka ±1 minggu; buka lagi dari dashboard bila terjadi.
- Cadangan data: menu Pengaturan → "Salin cadangan JSON"; pulihkan lewat "Pulihkan dari JSON".
