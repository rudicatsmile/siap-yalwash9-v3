<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;

class Document extends Model
{
    use HasFactory, SoftDeletes;

    /**
     * The table associated with the model.
     *
     * @var string
     */
    protected $table = 'tbl_sm';

    /**
     * The primary key associated with the table.
     *
     * @var string
     */
    protected $primaryKey = 'id_sm';

    /**
     * The attributes that are mass assignable.
     *
     * @var array<string>
     */
    protected $fillable = [
        'no_surat',
        'tgl_ns',
        'no_asal',
        'tgl_no_asal',
        'tgl_no_asal2',
        'tgl_surat',
        'pengirim',
        'penerima',
        'perihal',
        'token_lampiran',
        'token_lampiran_tu',
        'bagian',
        'disposisi',
        'id_user',
        'kode_user',
        'kode_user_approved',
        'id_user_approved',
        'id_instansi',
        'id_instansi_approved',
        'id_user_disposisi_leader',
        'tgl_sm',
        'lampiran',
        'status',
        'sifat',
        'dibaca',
        'dibaca_pimpinan',
        'kode_user_pimpinan',
        'tgl_ajuan',
        'tgl_ajuan_delegate',
        'segera',
        'biasa',
        'catatan',
        'tgl_disposisi',
        'tgl_approved',
        'catatan_koreksi',
        'is_notes_pimpinan',
        'status_tu',
        'status_instansi',
        'tgl_delegasi_rapat',
        'tgl_agenda_rapat',
        'tgl_hasil_rapat',
        'delegasi_pimpinan',
        'disposisi_rapat',
        'delegasi_tu',
        'ruang_rapat',
        'penanda_tangan_rapat',
        'tembusan_rapat',
        'jam_rapat',
        'bahasan_rapat',
        'pimpinan_rapat',
        'peserta_rapat',
        'ditujukan',
        'instruksi_kerja',
        'disposisi_memo',
        'kategori_berkas',
        'kategori_undangan',
        'kategori_laporan',
        'id_status_rapat',
        'kode_user_ditujukan_memo',
        'kategori_surat',
        'kode_berkas',
        'klasifikasi_surat',
        'disposisi_ktu_leader',
    ];

    /**
     * The attributes that should be cast.
     *
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            //'tgl_ns' => 'date',
            // 'tgl_no_asal' => 'date',
            // 'tgl_no_asal2' => 'date',
            // 'tgl_surat' => 'date',
            // 'tgl_sm' => 'date',
            // 'tgl_ajuan' => 'datetime',
            'tgl_ajuan_delegate' => 'datetime',
            'tgl_disposisi' => 'datetime',
            'tgl_approved' => 'datetime',
            'tgl_delegasi_rapat' => 'datetime',
            'tgl_hasil_rapat' => 'datetime',
            // 'dibaca' => 'boolean',
            // 'dibaca_pimpinan' => 'boolean',
            // 'is_notes_pimpinan' => 'boolean',
            // 'status_tu' => 'boolean',
            // 'status_instansi' => 'boolean',
            // 'delegasi_pimpinan' => 'boolean',
            'id_user_approved' => 'integer',
        ];
    }

    /**
     * Get the user that created the document.
     */
    public function user()
    {
        return $this->belongsTo(User::class, 'id_user', 'id_user');
    }

    /**
     * Get the activity history for this document.
     */
    public function activities()
    {
        return $this->hasMany(ActivityHistory::class, 'document_id', 'id_sm');
    }

    /**
     * Scope a query to only include documents with a specific status.
     */
    public function scopeStatus($query, string $status)
    {
        return $query->where('status', $status);
    }

    /**
     * Scope a query to only include documents for a specific institution.
     */
    public function scopeForInstitution($query, string $institutionId)
    {
        return $query->where('id_instansi', $institutionId);
    }

    /**
     * Scope a query to only include meetings (status = Rapat).
     */
    public function scopeMeetings($query)
    {
        return $query->where('status', 'Rapat');
    }

    /**
     * Scope a query to search documents.
     */
    public function scopeSearch($query, string $search)
    {
        return $query->where(function ($q) use ($search) {
            $q->where('no_surat', 'like', "%{$search}%")
                ->orWhere('pengirim', 'like', "%{$search}%")
                ->orWhere('perihal', 'like', "%{$search}%");
        });
    }

    /**
     * Mark document as read.
     */
    public function markAsRead(bool $isPimpinan = false): void
    {
        if ($isPimpinan) {
            $this->update(['dibaca_pimpinan' => true]);
        } else {
            $this->update(['dibaca' => true]);
        }
    }

    /**
     * Check if document can be edited.
     */
    public function canBeEdited(): bool
    {
        return $this->status === 'Dokumen';
    }

    /**
     * Check if document can be deleted.
     */
    public function canBeDeleted(): bool
    {
        return empty($this->disposisi);
    }
}
