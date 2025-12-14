<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Lampiran extends Model
{
    use HasFactory;

    protected $table = 'tbl_lampiran';

    protected $fillable = [
        'no_surat',
        'token_lampiran',
        'nama_berkas',
        'ukuran',
        'path',
    ];

    public function document()
    {
        return $this->belongsTo(Document::class, 'no_surat', 'no_surat');
    }
}
