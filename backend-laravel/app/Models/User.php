<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens;
use Illuminate\Database\Eloquent\SoftDeletes;

class User extends Authenticatable
{
    use HasFactory, Notifiable, HasApiTokens, SoftDeletes;

    /**
     * The table associated with the model.
     *
     * @var string
     */
    protected $table = 'users';

    /**
     * The primary key associated with the table.
     *
     * @var string
     */
    protected $primaryKey = 'id_user';

    /**
     * The attributes that are mass assignable.
     *
     * @var list<string>
     */
    protected $fillable = [
        'username',
        'password',
        'nama_lengkap',
        'jabatan',
        'role',
        'instansi',
        'email',
        'telp',
        'alamat',
        'pengalaman',
        'level',
        'level_pimpinan',
        'level_tu',
        'level_admin',
        'level_manajemen',
        'kode_user',
        'status',
        'tgl_daftar',
        'terakhir_login',
        'fcm_token',
        'login_attempts',
        'last_attempt',
        'blocked_until',
        'failed_ip',
    ];

    /**
     * The attributes that should be hidden for serialization.
     *
     * @var list<string>
     */
    protected $hidden = [
        'password',
        'token',
    ];

    /**
     * Get the attributes that should be cast.
     *
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'tgl_daftar' => 'datetime',
            'terakhir_login' => 'datetime',
            'last_attempt' => 'datetime',
            'blocked_until' => 'datetime',
            'password' => 'hashed',
            'login_attempts' => 'integer',
        ];
    }

    /**
     * Get the documents created by this user.
     */
    public function documents()
    {
        return $this->hasMany(Document::class, 'id_user', 'id_user');
    }

    /**
     * Get the activity history for this user.
     */
    public function activities()
    {
        return $this->hasMany(ActivityHistory::class, 'user_id', 'id_user');
    }

    /**
     * Check if user account is blocked.
     */
    public function isBlocked(): bool
    {
        return $this->blocked_until && now()->lessThan($this->blocked_until);
    }

    /**
     * Check if user is admin.
     */
    public function isAdmin(): bool
    {
        return $this->role === 'admin';
    }

    /**
     * Check if user is pimpinan (leadership).
     */
    public function isPimpinan(): bool
    {
        return $this->role === 'pimpinan';
    }

    /**
     * Increment login attempts.
     */
    public function incrementLoginAttempts(string $ipAddress): void
    {
        $this->increment('login_attempts');
        $this->update([
            'last_attempt' => now(),
            'failed_ip' => $ipAddress,
        ]);

        if ($this->login_attempts >= 5) {
            $this->update([
                'blocked_until' => now()->addMinutes(30),
            ]);
        }
    }

    /**
     * Reset login attempts.
     */
    public function resetLoginAttempts(): void
    {
        $this->update([
            'login_attempts' => 0,
            'last_attempt' => null,
            'blocked_until' => null,
            'failed_ip' => null,
        ]);
    }
}
