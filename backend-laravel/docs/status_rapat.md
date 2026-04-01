# Status Rapat API

Endpoint: `GET /api/status-rapat`

- Returns JSON with `success` and `data`
- `data` is an array of objects with:
  - `id_status`: string
  - `nama_status`: string

Query params:
- `search` (optional): filters `nama_status` using LIKE

Responses:
- 200: `{ success: true, data: [...] }`
- 404: `{ success: false, message: 'Tabel tidak ditemukan' | 'Struktur tabel tidak kompatibel' }`
- 500: `{ success: false, message: 'Terjadi kesalahan pada server' }`
