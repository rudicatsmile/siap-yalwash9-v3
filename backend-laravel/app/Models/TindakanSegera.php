<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class TindakanSegera extends Model
{
    use HasFactory;

    protected $table = 'm_tindakan_segera';

    protected $fillable = [
        'kode',
        'deskripsi',
        'keterangan',
    ];
}

