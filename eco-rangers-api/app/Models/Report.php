<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Facades\Storage;

class Report extends Model
{
    protected $fillable = [
            'judul','deskripsi','lokasi_text','lat','lng','foto_path','status'
        ];


    // supaya ikut tampil di JSON
    protected $appends = ['foto_url'];

    public function getFotoUrlAttribute()
    {
        return $this->foto_path
            ? url(Storage::url($this->foto_path)) // contoh: http://127.0.0.1:8000/storage/reports/xxx.png
            : null;
    }
}
