<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use App\Models\Report;

class ReportController extends Controller
{
    public function index()
    {
        // tampilkan semua laporan + url foto
        $data = Report::orderByDesc('id')->get()->map(function ($r) {
            $r->foto_url = $r->foto_path ? asset('storage/'.$r->foto_path) : null;
            return $r;
        });
        return response()->json($data);
    }

    public function show(Report $report)
    {
        $report->foto_url = $report->foto_path ? asset('storage/'.$report->foto_path) : null;
        return response()->json($report);
    }

    // ====== PERBAIKAN ADA DI SINI ======
    public function store(Request $request)   // <<— wajib ada Request $request
    {
        // validasi input
        $validated = $request->validate([
            'judul'       => ['required','string','max:255'],
            'deskripsi'   => ['required','string'],
            'lokasi_text' => ['nullable','string'],
            'lat'         => ['nullable','numeric'],
            'lng'         => ['nullable','numeric'],
            'foto'        => ['nullable','image','mimes:jpg,jpeg,png','max:4096'], // ~4MB
        ]);

        // simpan file jika ada
        $path = null;
        if ($request->hasFile('foto')) {
            // ke storage/app/public/reports
            $path = $request->file('foto')->store('reports', 'public');
        }

        // buat record
        $report = Report::create([
            'judul'       => $validated['judul'],
            'deskripsi'   => $validated['deskripsi'],
            'lokasi_text' => $validated['lokasi_text'] ?? null,
            'lat'         => $validated['lat'] ?? null,
            'lng'         => $validated['lng'] ?? null,
            'foto_path'   => $path,
            'status'      => 'Pending',
        ]);

        $report->foto_url = $path ? asset('storage/'.$path) : null;

        return response()->json($report, 201);
    }

    public function updateStatus(Request $request, Report $report)
    {
        $request->validate([
            'status' => ['required','in:Pending,Diproses,Selesai'],
        ]);
        $report->status = $request->input('status');
        $report->save();

        $report->foto_url = $report->foto_path ? asset('storage/'.$report->foto_path) : null;
        return response()->json($report);
    }

    public function destroy(Report $report)
    {
        if ($report->foto_path) {
            Storage::disk('public')->delete($report->foto_path);
        }
        $report->delete();
        return response()->json(['deleted' => true]);
    }
}
