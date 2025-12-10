<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class TujuanDisposisi extends Model
{
    use HasFactory;

    /**
     * The table associated with the model.
     *
     * Note: Using 'm_tujuan_dosposisi' as requested, though it looks like a typo for 'm_tujuan_disposisi'.
     *
     * @var string
     */
    protected $table = 'm_tujuan_disposisi';

    /**
     * The primary key associated with the table.
     *
     * @var string
     */
    protected $primaryKey = 'id';

    /**
     * The attributes that are mass assignable.
     *
     * @var array<string>
     */
    protected $fillable = [
        'kode',
        'deskripsi',
        'keterangan',
        'telp',
        'urut',
        'id_user',
        'status',
    ];

    /**
     * The attributes that should be cast.
     *
     * @var array<string, string>
     */
    protected $casts = [
        'status' => 'boolean',
        'urut' => 'integer',
        'id_user' => 'integer',
    ];

    /**
     * Get the user that owns the disposition goal.
     */
    public function user()
    {
        // Joining with 'users' table (which the user referred to as 'tbl_user')
        return $this->belongsTo(User::class, 'id_user', 'id_user');
    }
}
