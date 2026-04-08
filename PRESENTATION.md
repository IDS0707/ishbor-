# 🏢 ISHBOR — Ish Topish Platformasi
### Loyiha Taqdimoti (Prezentatsiya)

---

## 📌 Slide 1 — Loyiha haqida umumiy ma'lumot

| Parametr | Ma'lumot |
|---|---|
| 📛 Nomi | **Ishbor** (Job Finder App) |
| 📅 Yozilgan yili | **2026-yil (aprel)** |
| 🧑‍💻 Frontend tili | **Dart 3.0+ (Flutter framework)** |
| 🔙 Backend tili | **JavaScript / Node.js** (Firebase Cloud Functions) |
| ☁️ Backend platforma | **Google Firebase** (Firestore, Auth, FCM) |
| 📱 Platformalar | Android + Web (bitta kod bazasi) |
| 🏛️ Arxitektura | **Clean Architecture + Riverpod** |
| 🌍 Tillar | O'zbekcha, Ruscha, Inglizcha (3 til) |
| 🔗 GitHub | github.com/IDS0707/ishbor- |

---

## 📌 Slide 2 — Muammo va Yechim

### ❌ Muammo (O'zbekistonda):
- Oddiy ishchilar (qurilishchi, oshpaz, haydovchi) ish izlash uchun **og'ir platformalar** bilan qiynaladi
- Ko'pchilik vakansiya saytlari murakkab, **ro'yxatdan o'tish uzoq** davom etadi
- Geolokatsiya va kategoriya bo'yicha **tez filter** yo'q
- Ish beruvchi bilan **to'g'ridan-to'g'ri muloqot** imkoni cheklangan

### ✅ Yechim — Ishbor:
- Telefon raqami bilan **30 soniyada** ro'yxatdan o'tish
- **50+ kasb kategoriyasi** bo'yicha qidirish
- Xaritada **joylashuvni ko'rish**, yaqin ishlarni topish
- Ish beruvchi bilan **real-time chat** + push bildirishnomalar
- **Ish beruvchi uchun**: ishchilarni o'zi topib, ularga murojaat qilishi

---

## 📌 Slide 3 — Foydalanuvchi rollari

### 👤 Rol tanlash (Kirish paytida)
Ilova ikki turdagi foydalanuvchini qo'llab-quvvatlaydi:

```
Kirish → Telefon OTP → Rol tanlash
                            ├── 🔵 Ish Izlayapman  →  HomeScreen (vakansiyalar lenti)
                            └── 🟢 Ish Bermoqchiman →  EmployerHomeScreen (mening vakansiyalarim)
```

### 🔵 Ish izlovchi profili:
| Maydon | Tavsif |
|---|---|
| Ism | To'liq ism |
| Telefon | Bog'lanish uchun |
| Kasb kategoriyalari | Ko'p tanlash mumkin (IT, haydovchi, oshpaz va b.) |
| Ko'nikmalar | Erkin matn — "Men nima qila olaman" |
| Yosh | Yosh (va jins — ixtiyoriy) |

### 🟢 Ish beruvchi profili:
| Maydon | Tavsif |
|---|---|
| Kompaniya/Ism | Ish beruvchi ismi |
| Telefon | Firebase Auth orqali tasdiqlangan |
| Vakansiyalar | Joylashtirilgan barcha e'lonlar |

---

## 📌 Slide 4 — Vakansiya modeli (Ma'lumot tuzilmasi)

Har bir vakansiya quyidagi ma'lumotlarni saqlaydi:

| Maydon | Turi | Tavsifi |
|---|---|---|
| `title` | String | Lavozim nomi |
| `salary` | String | Maosh (so'm yoki kelishiladi) |
| `phone` | String | Bog'lanish telefon raqami |
| `category` | String | 50+ kategoriyadan biri |
| `description` | String | Batafsil tavsif |
| `region` | String | Viloyat / shahar |
| `workAddress` | String | Aniq ish manzili |
| `workStart` / `workEnd` | String | Ish vaqti (09:00 — 18:00) |
| `latitude` / `longitude` | double | GPS koordinatalari (xarita uchun) |
| `employmentType` | String | To'liq / yarim / bir martalik |
| `ageMin` / `ageMax` | int | Yosh chegarasi |
| `gender` | String | Erkak / Ayol / Farqi yo'q |
| `createdAt` | DateTime | Joylashtirilgan vaqt |

---

## 📌 Slide 5 — Ish kategoriyalari (50+ kasb)

Ilova **50 dan ortiq kasb kategoriyasini** qo'llab-quvvatlaydi:

| Soha | Kategoriyalar |
|---|---|
| 💻 IT & Dizayn | Dasturchi, Dizayner, Fotograf, Animatsiya |
| 🏗️ Qurilish | Qurilishchi, Elektrik, Santexnik, Payvandchi, Bo'yoqchi |
| 🍳 Oziq-ovqat | Oshpaz, Ofitsiant, Nonvoy |
| 🚗 Transport | Haydovchi, Kuryer, Yuk tashuvchi |
| 📚 Ta'lim | O'qituvchi, Tarjimon, Psixolog |
| 🏥 Sog'liqni saqlash | Shifokor, Hamshira, Farmatsevt, Veterinar |
| 💼 Biznes | Buxgalter, Marketing, Huquqshunos, Rieltyor |
| 💈 Xizmat | Sartarosh, Go'zallik ustasi, Bog'bon, Fitnes |
| 🏨 Mehmonxona | Resepsyon, Mehmonxona xodimi, Ijtimoiy ishchi |
| 🎭 Ijod | Jurnalist, Aktyor, Musiqachi |
| ➕ Qo'shimcha | Omborchi, Kassir, Sotuvchi, Qorovul, Tozalovchi va b. |

---

## 📌 Slide 6 — Frontend (Mobil ilova) — Texnologiyalar

### Asosiy texnologiyalar:

```
Flutter 3.0+  (Dart 3.0 tili)
├── Material Design 3       — zamonaviy Google UI tizimi
├── Google Fonts            — Poppins va boshqa shriftlar
├── Flutter Riverpod 2.x    — reaktiv state management
├── Hive / SharedPreferences — lokal ma'lumot saqlash
├── flutter_map + latlong2  — OpenStreetMap asosidagi xarita
├── geolocator              — GPS joylashuvni aniqlash
├── permission_handler      — Android ruxsatlar boshqaruvi
├── url_launcher            — Telegram/WhatsApp/Telefon chaqirish
└── connectivity_plus       — internet aloqa tekshirish
```

### Nima uchun Flutter?
- ✅ **Bitta kod** — Android ham, Web ham chiqadi
- ✅ Native tezlikda ishlaydi (AOT compiled)
- ✅ Hot reload — tez rivojlantirish
- ✅ Google tomonidan qo'llab-quvvatlanadi
- ✅ Material Design 3 — zamonaviy dizayn standartlari

---

## 📌 Slide 7 — Backend texnologiyalari

### Google Firebase xizmatlari:

```
Google Firebase (Serverless Backend)
├── Firebase Auth           — Autentifikatsiya
│   ├── Telefon OTP (SMS)  — asosiy usul
│   └── Email/Parol        — qo'shimcha usul
│
├── Cloud Firestore         — Real-time NoSQL ma'lumotlar bazasi
│   ├── /jobs/             — vakansiyalar
│   ├── /users/            — foydalanuvchi profillari
│   ├── /worker_profiles/  — ishchi profillari
│   ├── /chats/            — chat meta ma'lumotlari
│   ├── /chats/{id}/messages/ — xabarlar
│   └── /notifications/    — bildirishnomalar
│
├── Firebase Messaging (FCM) — Push bildirishnomalar
│   ├── onNewChatMessage trigger  — yangi xabarda bildirishnoma
│   └── FCM token boshqaruvi
│
└── Cloud Functions (Node.js) — Server logikasi
    └── onNewChatMessage()   — auto push notification trigger
```

### Nima uchun Firebase?
- ✅ **Serverless** — server sotib olish va boshqarish shart emas
- ✅ Real-time Stream — ma'lumotlar o'zgarishi darhol ekranda ko'rinadi
- ✅ **Avtomatik scaling** — 1 foydalanuvchidan 1 milliongacha
- ✅ **Bepul kvota** bor (Spark plan)
- ✅ Google infratuzilmasi — ishonchli va tez

---

## 📌 Slide 8 — Ekranlar (Screens) — 15 ta ekran

| # | Ekran nomi | Funksiyasi |
|---|---|---|
| 1 | **SplashScreen** | Ilova yuklanish ekrani, sessiya tekshirish |
| 2 | **LoginScreen** | Email/telefon bilan kirish sahifasi |
| 3 | **PhoneAuthScreen** | SMS OTP kod yuborish va tasdiqlash |
| 4 | **RoleSelectionScreen** | Ish izlovchi / Ish beruvchi tanlash |
| 5 | **HomeScreen** | Ish izlovchi bosh ekran — vakansiyalar lenti |
| 6 | **EmployerHomeScreen** | Ish beruvchi bosh ekran — mening e'lonlarim |
| 7 | **JobDetailScreen** | Vakansiya batafsil sahifasi |
| 8 | **PostJobScreen** | Yangi vakansiya qo'shish / tahrirlash |
| 9 | **ChatScreen** | Real-time xabar almashish ekrani |
| 10 | **BrowseSeekersScreen** | Ishchilarga moslab qidiruv ekrani |
| 11 | **WorkerProfileSetupScreen** | Ishchi profili sozlash |
| 12 | **ProfileScreen** | Foydalanuvchi profili ko'rish |
| 13 | **SettingsScreen** | Sozlamalar — til, tema, hisob o'chirish |
| 14 | **MapPickerScreen** | Xaritadan joylashuv tanlash |
| 15 | **QuestionsScreen** | Tez-tez beriladigan savollar / yordam |

---

## 📌 Slide 9 — Asosiy funksiyalar (Batafsil)

### 🔍 Qidirish va Filterlash:
- Matn bo'yicha qidirish (debounce bilan — har harf bosishda emas)
- **Kategoriya** bo'yicha filter (50+ kasb)
- **Viloyat / shahar** bo'yicha filter
- **Ish turi** bo'yicha filter: To'liq stavka / Yarim stavka / Bir martalik
- Faol filterlar soni badge ko'rinishida ko'rsatiladi

### 💬 Real-time Chat tizimi:
- Har bir vakansiya bo'yicha alohida chat mavjud
- Chat ID: `{jobId}_{seekerUid}` formulasi bilan yaratiladi
- Xabarlar Firestore Stream orqali real-time yangilanadi
- O'qilmagan xabarlar soni bildirishnoma badge sifatida ko'rinadi
- **Cloud Function** trigger: yangi xabar → FCM push notification

### 🗺️ Xarita integratsiyasi:
- Vakansiya qo'shishda xaritadan joylashuv belgilash
- OpenStreetMap (bepul, litsenziyasiz) asosida
- GPS orqali foydalanuvchi joylashuvini aniqlash

### 🔔 Push Bildirishnomalar:
```
Chat xabari yoziladi (Firestore)
        ↓
Cloud Function (Node.js) trigger ishlaydi
        ↓
Qabul qiluvchining FCM tokeni olinadi
        ↓
FCM orqali qurilmaga push notification yuboriladi
        ↓
Foydalanuvchi bildirishnomani bosadi → ChatScreen ochiladi
```

### ❤️ Sevimlilar:
- SharedPreferences orqali lokal saqlash
- Internet bo'lmasa ham ishlaydi
- Har bir yangi sessiyada saqlanib qoladi

---

## 📌 Slide 10 — Ko'p tillilik (Lokalizatsiya)

Ilova **3 tilda** to'liq tarjima qilingan:

| Til | Kod | Holat |
|---|---|---|
| 🇺🇿 O'zbekcha (Lotin) | `uz` | Asosiy til |
| 🇷🇺 Ruscha | `ru` | To'liq tarjima |
| 🇬🇧 Inglizcha | `en` | To'liq tarjima |

**Qanday ishlaydi:**
```dart
// Har bir matndagi kalit so'z
L10n.t('tagline', appLocale.value)

// uz: "O'zbekistonda ish toping yoki e'lon bering"
// ru: "Найдите работу или разместите вакансию в Узбекистане"
// en: "Find or post jobs in Uzbekistan"
```

- Til o'zgartirish darhol kuchga kiradi (restart shart emas)
- 200+ tarjima kaliti mavjud

---

## 📌 Slide 11 — Arxitektura (Clean Architecture)

```
┌────────────────────────────────────────────────┐
│              UI Layer (Flutter Screens)        │
│  SplashScreen → LoginScreen → HomeScreen ...   │
└────────────────────────────────────────────────┘
               ↕ (State listen)
┌────────────────────────────────────────────────┐
│         Core & State Management                │
│  Riverpod Providers | L10n | AppTheme          │
│  Categories | Responsive | AppLocale           │
└────────────────────────────────────────────────┘
               ↕ (Service calls)
┌────────────────────────────────────────────────┐
│              Services Layer                    │
│  AuthService | FirestoreService                │
│  NotificationService | FavoritesService        │
└────────────────────────────────────────────────┘
               ↕ (Firebase SDK calls)
┌────────────────────────────────────────────────┐
│           Firebase (Google Cloud)              │
│  Auth | Firestore | FCM | Cloud Functions      │
└────────────────────────────────────────────────┘
```

**Prinsiplar:**
- Har bir qatlam faqat o'zidan pastdagi qatlam bilan gaplashadi
- UI biznes logikani bilmaydi
- Service layer Firebase SDK bilan to'g'ridan-to'g'ri ishlaydi

---

## 📌 Slide 12 — Xavfsizlik

| Xavfsizlik chorasi | Amalga oshirish usuli |
|---|---|
| 🔐 Autentifikatsiya | Firebase Phone OTP — SMS tasdiqlash |
| 🔑 Qo'shimcha kirish | Email + Parol (Firebase Auth) |
| 🛡️ Ma'lumotlar himoyasi | Firestore Security Rules — faqat o'z ma'lumotini o'zgartirish |
| 📵 Parolsiz kirish | Telefon OTP — parol yodlash shart emas |
| 🚫 Soxta ma'lumot | Ish beruvchilarga **qonuniy ogohlantirish** ko'rsatiladi |
| 🔔 FCM xavfsizligi | Token asosida — boshqa qurilmaga notification borishi imkonsiz |
| 🗑️ Hisob o'chirish | Foydalanuvchi o'z hisobini to'liq o'chira oladi |

**Ogohlantirish (ilova ichida ko'rsatiladi):**
> ⚠️ Yolg'on yoki boshqa shaxsning ma'lumotlarini ko'rsatish qonunga zid bo'lib, jinoiy javobgarlikka tortilishingizga olib keladi.

---

## 📌 Slide 13 — UI/UX dizayn

### Ranglar va Dizayn:
- **Material Design 3** — Google'ning eng zamonaviy dizayn tizimi
- **Dark Mode** (standart) va **Light Mode** — foydalanuvchi tanlaydi
- **Poppins** shrifti (Google Fonts) — zamonaviy, o'qilishi oson
- Ranglar: `#0EA5E9` (ko'k asosiy) + `#1E293B` (to'q qora fon)

### Responsive dizayn:
- Kichik telefon (360px) dan katta ekrangacha moslashadi
- `Responsive` utilit class orqali — `isSmall`, `isMedium`, `isLarge`
- Web uchun keng ekran layouti alohida

### Animatsiyalar:
- Ekranlar orasida silliq o'tishlar (`MaterialPageRoute`)
- Chat xabarlar animatsiyali paydo bo'ladi
- Filter badge animatsiyali yangilanadi

---

## 📌 Slide 14 — Loyiha statistikasi

| Parametr | Qiymat |
|---|---|
| 📁 Jami Dart fayllari | **40+** |
| 🖥️ Ekranlar soni | **15 ta** |
| 🗂️ Kasb kategoriyalari | **50+** |
| 🌍 Tillar soni | **3 ta** (uz, ru, en) |
| 📦 Flutter paketlar | **20+** |
| ⚙️ Cloud Functions | **1 ta** (Node.js) |
| 🗄️ Firestore kolleksiyalar | **6 ta** (jobs, users, chats, messages, notifications, worker_profiles) |
| 📱 Platforma | **Android + Web** |
| 🏗️ Arxitektura | **Clean Architecture** |

---

## 📌 Slide 15 — Raqobatchilar bilan taqqoslash

| Xususiyat | Ishbor | OLX | HeadHunter |
|---|---|---|---|
| 🇺🇿 O'zbek tili | ✅ | ✅ | ⚠️ |
| 📱 Mobil ilovasi | ✅ Android+Web | ✅ | ✅ |
| ⚡ Tez ro'yxatdan o'tish | ✅ 30 sek | ❌ Uzoq | ❌ Uzoq |
| 💬 Real-time chat | ✅ | ❌ | ❌ |
| 🗺️ Xaritada ko'rish | ✅ | ⚠️ | ❌ |
| 🔔 Push notification | ✅ | ✅ | ✅ |
| 👷 Oddiy ishchilar uchun | ✅ Moslashgan | ⚠️ | ❌ |
| 🆓 Bepul asosiy plan | ✅ | ✅ | ⚠️ |
| 🔍 Ishchi qidiruv | ✅ | ⚠️ | ✅ |

---

## 📌 Slide 16 — Kelajak rejalari

### Qo'shilishi mumkin bo'lgan funksiyalar:
- 📊 **Admin panel** — statistika va moderatsiya
- ⭐ **Reyting tizimi** — ish beruvchi va ishchilarni baholash
- 📄 **CV yuklash** — PDF rezyume qo'shish
- 🤖 **AI tavsiyalar** — profiliga mos ish tavsiya qilish
- 💳 **Premium e'lon** — vakansiyani yuqoriga chiqarish
- 🌏 **Boshqa viloyatlar** — geografik kengayish
- 📞 **Video qo'ng'iroq** — suhbat uchun

---

## 📌 Slide 17 — Xulosa

> **"Ishbor"** — O'zbekistonda oddiy ishchilarni ish beruvchilarga **tez, qulay va xavfsiz** ulaydigan zamonaviy platforma.

### Texnologik stek:
```
Frontend:     Flutter (Dart 3.0)     → Android + Web
Backend:      Google Firebase        → Auth + Firestore + FCM
Server logic: Node.js (Cloud Func.)  → Push bildirishnomalar
Arxitektura:  Clean Architecture     → Mustaqil qatlamlar
Til qo'llab:  O'zbek + Rus + Ingliz → 3 til
```

### Asosiy yutuqlar:
- ✅ 15 ta to'liq ekran
- ✅ 50+ kasb kategoriyasi
- ✅ Real-time chat + push bildirishnomalar
- ✅ Xarita va GPS integratsiyasi
- ✅ 3 tilli interfeys
- ✅ Dark/Light mode
- ✅ Android va Web da ishlaydi

---

*Taqdimot tayyorlangan: 2026-yil, aprel*
*Loyiha: github.com/IDS0707/ishbor-*
*Texnologiya: Flutter + Firebase + Node.js*
