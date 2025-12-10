<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class TipeSurat extends Model
{
    use HasFactory;

    protected $table = 'm_tipe_surat';

    protected $primaryKey = 'id_tipe_surat';

    protected $fillable = [
        'klasifikasi_surat_keluar',
        'kode',
    ];
}

