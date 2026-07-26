# Medihelp

<p align="left">
  <img src="https://img.shields.io/badge/Flutter-02569B?style=flat-square&logo=flutter&logoColor=white" alt="Flutter">
  <img src="https://img.shields.io/badge/Dart-0175C2?style=flat-square&logo=dart&logoColor=white" alt="Dart">
  <img src="https://img.shields.io/badge/Platform-Android%20%7C%20iOS-brightgreen?style=flat-square" alt="Platform">
  <img src="https://img.shields.io/badge/License-MIT-yellow?style=flat-square" alt="License">
</p>

## About

**Medihelp** is a comprehensive mobile health assistant designed to help users manage their healthcare journey effectively. Built with Flutter, this cross-platform application combines essential health management tools with an intuitive user interface.

### Fitur Aplikasi

| No | Fitur | Deskripsi | Halaman Utama |
|:--:|-------|-----------|---------------|
| 1 | **Beranda** | Dashboard utama menampilkan ringkasan informasi, menu cepat, dan jadwal obat hari ini | `home_page.dart` |
| 2 | **Jadwal Pengingat Obat** | Mengatur jadwal minum obat dengan notifikasi pengingat | `schedule_page.dart` |
| 3 | **Riwayat Obat** | Mencatat dan menampilkan history konsumsi obat | `history_page.dart` |
| 4 | **Fasilitas Kesehatan Terdekat** | Mencari rumah sakit, klinik, dan apotek terdekat dengan Google Maps | `nearby_page.dart` |
| 5 | **Antrian Online** | Mengambil dan memantau antrian online di fasilitas kesehatan | `queue_page.dart` |
| 6 | **Autentikasi** | Login, register, dan manajemen akun pengguna | `login_page.dart` |

---

### Project Goals

- Create a user-friendly health management tool accessible to everyone
- Implement clean Flutter architecture with separation of concerns
- Demonstrate practical mobile development skills
- Provide real value for daily health management

### Technology Stack

- **Framework:** Flutter (SDK)
- **Language:** Dart
- **State Management:** [Provider](https://pub.dev/packages/provider) / [Riverpod](https://pub.dev/packages/riverpod)
- **Local Storage:** MySQL / [SharedPreferences](https://pub.dev/packages/shared_preferences)
- **Notifications:** [Flutter Local Notifications](https://pub.dev/packages/flutter_local_notifications)
- **API Integration:** [Dio](https://pub.dev/packages/dio) / [HTTP](https://pub.dev/packages/http)

## Project Structure

Berikut adalah struktur folder aplikasi Medihelp:
```
lib/
├── main.dart
├── core/
│   ├── constants/
│   │   ├── app_strings.dart           # Semua teks
│   │   ├── app_colors.dart            # Warna tema
│   │   └── api_endpoints.dart         # URL API (Google Maps, RS, dll)
│   ├── theme/
│   │   └── app_theme.dart             # Tema aplikasi
│   ├── utils/
│   │   ├── date_formatter.dart        # Format tanggal untuk jadwal
│   │   ├── location_helper.dart       # Bantuan lokasi (GPS)
│   │   └── validators.dart            # Validasi input
│   └── widgets/
│       ├── custom_app_bar.dart        # App bar kustom
│       ├── loading_widget.dart        # Indikator loading
│       ├── error_widget.dart          # Tampilan error
│       └── empty_state_widget.dart    # Tampilan data kosong
│
├── features/
│   ├── home/                          # FITUR 1: BERANDA
│   │   ├── presentation/
│   │   │   ├── pages/
│   │   │   │   └── home_page.dart     # Halaman utama
│   │   │   └── widgets/
│   │   │       ├── greeting_card.dart # Sapaan pengguna
│   │   │       ├── quick_action_grid.dart # Grid menu cepat
│   │   │       ├── today_schedule_card.dart # Ringkasan jadwal hari ini
│   │   │       └── health_tip_widget.dart # Tips kesehatan
│   │   └── providers/
│   │       └── home_provider.dart
│   │
│   ├── medication_schedule/            # FITUR 2: JADWAL PENGINGAT OBAT
│   │   ├── presentation/
│   │   │   ├── pages/
│   │   │   │   ├── schedule_page.dart     # Daftar jadwal
│   │   │   │   ├── add_schedule_page.dart # Tambah jadwal
│   │   │   │   └── edit_schedule_page.dart # Edit jadwal
│   │   │   └── widgets/
│   │   │       ├── schedule_card.dart     # Card jadwal
│   │   │       ├── time_picker.dart       # Pilih waktu
│   │   │       └── repeat_option.dart     # Opsi pengulangan
│   │   ├── domain/
│   │   │   ├── models/
│   │   │   │   └── medication_schedule.dart # Model jadwal
│   │   │   └── repositories/
│   │   │       └── schedule_repository.dart
│   │   └── data/
│   │       ├── repositories/
│   │       │   └── schedule_repository_impl.dart
│   │       └── datasources/
│   │           ├── local_schedule_datasource.dart  # DB SQLite
│   │           └── notification_service.dart       # Notifikasi
│   │
│   ├── medication_history/              # FITUR 3: RIWAYAT OBAT
│   │   ├── presentation/
│   │   │   ├── pages/
│   │   │   │   ├── history_page.dart       # Daftar riwayat
│   │   │   │   └── history_detail_page.dart # Detail riwayat
│   │   │   └── widgets/
│   │   │       ├── history_card.dart       # Card riwayat
│   │   │       ├── calendar_view.dart      # Tampilan kalender
│   │   │       └── filter_widget.dart      # Filter tanggal
│   │   ├── domain/
│   │   │   ├── models/
│   │   │   │   └── medication_history.dart # Model riwayat
│   │   │   └── repositories/
│   │   │       └── history_repository.dart
│   │   └── data/
│   │       ├── repositories/
│   │       │   └── history_repository_impl.dart
│   │       └── datasources/
│   │           └── local_history_datasource.dart
│   │
│   ├── nearby_healthcare/                # FITUR 4: FASILITAS KESEHATAN TERDEKAT
│   │   ├── presentation/
│   │   │   ├── pages/
│   │   │   │   ├── nearby_page.dart         # Peta & daftar
│   │   │   │   └── facility_detail_page.dart # Detail fasilitas
│   │   │   └── widgets/
│   │   │       ├── map_view.dart            # Google Maps
│   │   │       ├── facility_card.dart       # Card fasilitas
│   │   │       ├── filter_facility.dart     # Filter (RS, Klinik, Apotek)
│   │   │       └── distance_badge.dart      # Jarak dari lokasi
│   │   ├── domain/
│   │   │   ├── models/
│   │   │   │   └── healthcare_facility.dart # Model fasilitas
│   │   │   └── repositories/
│   │   │       └── facility_repository.dart
│   │   └── data/
│   │       ├── repositories/
│   │       │   └── facility_repository_impl.dart
│   │       └── datasources/
│   │           ├── google_maps_service.dart  # Google Maps API
│   │           └── location_service.dart     # GPS service
│   │
│   ├── online_queue/                      # FITUR 5: ANTRIAN ONLINE
│   │   ├── presentation/
│   │   │   ├── pages/
│   │   │   │   ├── queue_page.dart          # Daftar antrian
│   │   │   │   ├── take_queue_page.dart     # Ambil antrian
│   │   │   │   ├── my_queue_page.dart       # Antrian saya
│   │   │   │   └── queue_detail_page.dart   # Detail antrian
│   │   │   └── widgets/
│   │   │       ├── queue_card.dart          # Card antrian
│   │   │       ├── queue_status.dart        # Status antrian
│   │   │       ├── estimated_time.dart      # Estimasi waktu
│   │   │       └── qr_code_widget.dart      # QR Code untuk antrian
│   │   ├── domain/
│   │   │   ├── models/
│   │   │   │   ├── queue.dart               # Model antrian
│   │   │   │   └── hospital.dart            # Model rumah sakit
│   │   │   └── repositories/
│   │   │       └── queue_repository.dart
│   │   └── data/
│   │       ├── repositories/
│   │       │   └── queue_repository_impl.dart
│   │       └── datasources/
│   │           ├── remote_queue_datasource.dart # API antrian
│   │           └── local_queue_datasource.dart  # Cache
│   │
│   └── auth/                               # FITUR TAMBAHAN: LOGIN/REGISTER
│       ├── presentation/
│       │   ├── pages/
│       │   │   ├── login_page.dart
│       │   │   ├── register_page.dart
│       │   │   └── forgot_password_page.dart
│       │   └── widgets/
│       │       └── auth_form.dart
│       ├── domain/
│       │   ├── models/
│       │   │   └── user.dart
│       │   └── repositories/
│       │       └── auth_repository.dart
│       └── data/
│           ├── repositories/
│           │   └── auth_repository_impl.dart
│           └── datasources/
│               ├── remote_auth_datasource.dart
│               └── local_auth_datasource.dart
│
├── services/                              # Layanan Global
│   ├── notification_service.dart          # Push notifications
│   ├── location_service.dart              # Layanan lokasi
│   ├── database_service.dart              # SQLite service
│   └── api_service.dart                   # API client
│
└── models/                                # Global models
    └── user.dart
```


## Getting Started

### Prerequisites
- Flutter SDK (^3.0.0)
- Dart SDK (^3.0.0)
- Android Studio / VS Code
- Git

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/Alifahh6/medihelp.git

## 📱 Tampilan Aplikasi

Berikut adalah tampilan antarmuka utama aplikasi MediHelp:

### Onboarding & Autentikasi
| Splash Screen | Login | Signin | 
|:---:|:---:| :---:|
| <img width="738" height="1600" alt="WhatsApp Image 2026-05-16 at 15 36 37" src="https://github.com/user-attachments/assets/32d806fd-5d71-4a46-a986-df1d377fe785" />| <img width="738" height="1600" alt="WhatsApp Image 2026-05-16 at 15 36 39 (2)" src="https://github.com/user-attachments/assets/42633854-4389-44bd-9334-d9e96918b164" /> | <img width="1080" height="2340" alt="WhatsApp Image 2026-05-16 at 15 36 39 (1)" src="https://github.com/user-attachments/assets/d0e157e3-9275-4560-9d35-e0c65d6725e3" /> |

### Halaman Utama & Profil
| Home | Profile |
|:---:|:---:|
| <img width="738" height="1600" alt="WhatsApp Image 2026-05-16 at 15 36 36" src="https://github.com/user-attachments/assets/4a24fa72-a8a2-426e-98cd-2798f6f40558" /> | <img width="738" height="1600" alt="WhatsApp Image 2026-05-16 at 15 36 38" src="https://github.com/user-attachments/assets/c6d018b6-701a-4850-9d4b-a3358b2e08f1" /> |

### Fitur Layanan Kesehatan
| History | Queue | Nearby | FAQ |
|:---:|:---:|:---:|:---:|
| <img width="738" height="1600" alt="WhatsApp Image 2026-05-16 at 15 50 51 (1)" src="https://github.com/user-attachments/assets/acfd4c17-be0a-4d23-9b8a-2f548a8e8574" /> | <img width="738" height="1600" alt="WhatsApp Image 2026-05-16 at 15 36 37 (2)" src="https://github.com/user-attachments/assets/533002a4-1dd0-4822-9c76-ee5aef5a1b7f" /> | <img width="738" height="1600" alt="WhatsApp Image 2026-05-16 at 15 36 38 (2)" src="https://github.com/user-attachments/assets/59932622-50a4-4be4-953b-523e15692500" /> | <img width="738" height="1600" alt="WhatsApp Image 2026-05-16 at 15 36 38 (1)" src="https://github.com/user-attachments/assets/dac03d5d-1ac1-4e11-8bfe-cc01c631a0f6" /> |

### Fitur Rekam Medis & Pengingat
| Record | Reminder | 
|:---:|:---:|
| <img width="1080" height="2340" alt="WhatsApp Image 2026-05-16 at 15 50 45" src="https://github.com/user-attachments/assets/67a6de40-4b5b-430e-80b6-143d68e79d02" /> | <img width="738" height="1600" alt="WhatsApp Image 2026-05-16 at 15 50 51" src="https://github.com/user-attachments/assets/21982ca5-6716-4676-8208-6b4749d277f0" /> |

### Dark Mode
| Home (Dark) | Reminder (Dark) |
|:---:|:---:|
| <img width="738" height="1600" alt="WhatsApp Image 2026-05-16 at 15 50 47 (1)" src="https://github.com/user-attachments/assets/dd673841-28b4-4f48-bcf2-1693bba3c28c" /> | <img width="738" height="1600" alt="WhatsApp Image 2026-05-16 at 15 50 50" src="https://github.com/user-attachments/assets/1219be3e-42d0-4006-ac87-2842d58f2c3c" />  | 
