# Panduan Packaging Windows dengan Inno Setup (Singkat & Jelas)

Panduan ini menjelaskan cara memaketkan (package) aplikasi Flutter Windows menjadi satu file installer `.exe` menggunakan **Inno Setup**, serta mengaktifkan fitur hapus folder data (`AppData`) secara bersih saat uninstal.

---

## Langkah 1: Build Flutter untuk Windows (Mode Release)
Jalankan perintah berikut di terminal proyek Flutter Anda untuk menghasilkan file binary Windows:
```bash
flutter build windows
```
Hasil build akan berada di direktori:
`build\windows\runner\Release\`

---

## Langkah 2: Instal Inno Setup
1. Unduh dan instal **Inno Setup** versi terbaru dari [jrsoftware.org](https://www.jrsoftware.org/).
2. Jalankan Inno Setup Compiler.

---

## Langkah 3: Gunakan Script Inno Setup (`.iss`)
Buat sebuah file baru bernama `installer_script.iss` di folder root proyek Anda, lalu tempelkan konfigurasi di bawah ini. 

*Catatan: Pastikan untuk mengganti `<CompanyName>` dan `<AppName>` sesuai dengan informasi yang tertulis di file `windows/runner/Runner.rc` proyek Anda agar lokasi AppData tepat.*

```pascal
[Setup]
AppName=TutorKu
AppVersion=1.0.0
DefaultDirName={autopf}\TutorKu
DefaultGroupName=TutorKu
OutputDir=output
OutputBaseFilename=TutorKuSetup
Compression=lzma
SolidCompression=yes

[Files]
; Menyalin hasil build Flutter Windows
Source: "build\windows\runner\Release\*"; DestDir: "{app}"; Flags: recursesubdirs createallsubdirs

[Icons]
; Membuat shortcut di Start Menu dan Desktop
Name: "{group}\TutorKu"; Filename: "{app}\tutorku.exe"
Name: "{autodesktop}\TutorKu"; Filename: "{app}\tutorku.exe"

[Code]
procedure CurUninstallStepChanged(CurUninstallStep: TUninstallStep);
var
  Response: Integer;
  AppDataPath: String;
begin
  // Dipanggil setelah proses uninstall selesai
  if CurUninstallStep = usPostUninstall then
  begin
    // Tampilkan peringatan hapus AppData
    Response := MsgBox(
      'Apakah Anda ingin menghapus seluruh data transaksi, riwayat order, dan pengaturan TutorKu dari komputer Anda?' #13#10 #13#10 +
      'PERINGATAN: Semua data lokal akan hilang secara permanen jika Anda tidak memiliki file backup.', 
      mbConfirmation, 
      MB_YESNO or MB_DEFBUTTON2
    );
    
    if Response = IDYES then
    begin
      // Mendapatkan path folder AppData Roaming milik aplikasi
      // Default Flutter: AppData\Roaming\<CompanyName>\<AppName>
      // Sesuai dengan konfigurasi default windows/runner/Runner.rc Anda
      AppDataPath := ExpandConstant('{userappdata}\com.example\tutorku');
      
      if DirExists(AppDataPath) then
      begin
        if DelTree(AppDataPath, True, True, True) then
          Log('Folder AppData TutorKu berhasil dihapus.')
        else
          Log('Gagal menghapus folder AppData.');
      end;
    end;
  end;
end;
```

---

## Langkah 4: Compile Installer
1. Buka file `installer_script.iss` menggunakan aplikasi **Inno Setup**.
2. Klik tombol **Build** -> **Compile** (atau tekan `F9`).
3. Setelah selesai, file installer single-file `.exe` Anda yang bernama `TutorKuSetup.exe` akan tersimpan di dalam folder `output/` di root proyek Anda.
4. Ketika pengguna menjalankan uninstaller dari Add/Remove Programs Windows, dialog konfirmasi di atas akan otomatis muncul untuk menanyakan apakah data AppData ingin dihapus secara permanen atau dipertahankan.
