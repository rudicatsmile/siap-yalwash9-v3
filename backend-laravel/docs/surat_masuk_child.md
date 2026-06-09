# Surat Masuk Child API (tbl_sm_child)

Endpoint: `POST /api/surat-masuk/child`

Auth: `auth:sanctum` (Bearer token required)

## Request JSON

Fields (required):
- `id_sm` (integer) – harus ada di `tbl_sm.id_sm`
- `no_asal` (string)
- `tgl_agenda_rapat` (string, format `Y-m-d`)
- `jam_rapat` (string, format `H:i:s`)
- `bahasan_rapat` (string)
- `pimpinan_rapat` (string)
- `peserta_rapat` (string)
- `id_status_rapat` (integer, harus `!= 1`)

## Success Response (201)

```json
{
  "success": true,
  "message": "Berhasil menambahkan data tbl_sm_child",
  "data": {
    "id_sm_child": 1,
    "id_sm": 123,
    "no_asal": "SM/001",
    "tgl_agenda_rapat": "2026-04-02",
    "jam_rapat": "10:30:00",
    "bahasan_rapat": "Pembahasan A",
    "pimpinan_rapat": "Pimpinan A",
    "peserta_rapat": "Peserta 1<br>Peserta 2",
    "id_status_rapat": 3,
    "created_at": "2026-04-02T08:00:00.000000Z",
    "updated_at": "2026-04-02T08:00:00.000000Z"
  }
}
```

## Error Responses

- 400 (validasi gagal / `id_status_rapat = 1`)

```json
{
  "success": false,
  "message": "Validasi gagal",
  "errors": {
    "jam_rapat": ["Format jam_rapat harus H:i:s"]
  }
}
```

- 500 (server error)

```json
{ "success": false, "message": "Gagal menambahkan data tbl_sm_child" }
```

## Example cURL

```bash
curl -X POST "http://localhost:8000/api/surat-masuk/child" \
  -H "Authorization: Bearer <TOKEN>" \
  -H "Content-Type: application/json" \
  -d '{
    "id_sm": 123,
    "no_asal": "SM/001",
    "tgl_agenda_rapat": "2026-04-02",
    "jam_rapat": "10:30:00",
    "bahasan_rapat": "Pembahasan A",
    "pimpinan_rapat": "Pimpinan A",
    "peserta_rapat": "Peserta 1<br>Peserta 2",
    "id_status_rapat": 3
  }'
```
