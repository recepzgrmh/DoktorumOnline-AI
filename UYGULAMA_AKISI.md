# DoktorumOnline AI - Uygulama Akış Rehberi

## 📋 İçindekiler

- [1. Açılış ve Kimlik Doğrulama](#1-açılış-ve-kimlik-doğrulama)
- [2. Giriş ve Kayıt Akışları](#2-giriş-ve-kayıt-akışları)
- [3. Mail Doğrulama Ekranı](#3-mail-doğrulama-ekranı)
- [4. İlk Kez Girişte Tutorial](#4-ilk-kez-girişte-tutorial)
- [5. ProfilesScreen](#5-profilesscreen)
- [6. Drawer Menüsü](#6-drawer-menüsü)
- [7. Şikayet Başlat (HomeScreen)](#7-şikayet-başlat-homescreen)
- [8. Yapay Zeka ile Soru-Cevap (OverviewScreen)](#8-yapay-zeka-ile-soru-cevap-overviewscreen)
- [9. Analiz Geçmişi (OldChatScreen)](#9-analiz-geçmişi-oldchatscreen)
- [10. PDF Analizi (PdfAnalysisScreen)](#10-pdf-analizi-pdfanalysisscreen)
- [11. Teknik Detaylar](#11-teknik-detaylar)
- [12. Veri Yapısı](#12-veri-yapısı)

---

## 1. Açılış ve Kimlik Doğrulama

### 🔄 Ana Akış

Uygulama `main.dart` ile başlar ve `Wrapper` widget'ına yönlendirilir. `Wrapper` içinde bir `StreamBuilder` ile `FirebaseAuth.instance.authStateChanges()` dinlenir.

### 📱 Senaryolar

| Durum             | Gösterilen                  | Yönlendirme                                                                      |
| ----------------- | --------------------------- | -------------------------------------------------------------------------------- |
| **Yükleniyor**    | `CircularProgressIndicator` | -                                                                                |
| **Hata**          | Hata konsola basılır        | `Opening` ekranı                                                                 |
| **Kullanıcı var** | -                           | Mail doğrulanmışsa → `ProfilesScreen`<br/>Mail doğrulanmamışsa → `VerifyAccount` |
| **Kullanıcı yok** | -                           | `Opening` ekranı                                                                 |

### 🔧 Teknik Detaylar

```dart
// main.dart - Firebase başlatma
await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
await FirebaseAuth.instance.setPersistence(Persistence.LOCAL);

// wrapper.dart - Auth state dinleme
StreamBuilder<User?>(
  stream: FirebaseAuth.instance.authStateChanges(),
  builder: (context, snapshot) {
    // Durum kontrolü ve yönlendirme
  }
)
```

---

## 2. Giriş ve Kayıt Akışları

### 🚪 Opening Ekranı

İki ana seçenek sunar:

- **"Giriş Yap"** → `SignIn` ekranı
- **"Kayıt Ol"** → `SignUp` ekranı

### 📝 Giriş Yap (SignIn)

**Bileşenler:**

- E-posta ve şifre input'ları
- "Giriş Yap" butonu
- "Şifremi Unuttum" butonu → `ResetPassword` ekranı
- "Hesap Oluştur" butonu → `SignUp` ekranı
- Google & Facebook giriş (şu anda sadece Google aktif)

**Akış:**

1. Firebase Auth ile giriş yapılır
2. Başarılı girişte `Wrapper`'a yönlendirilir
3. Hata durumunda SnackBar ile bilgi verilir

### 📋 Kayıt Ol (SignUp)

**Bileşenler:**

- Ad, soyad, e-posta, şifre input'ları
- "Kayıt Ol" butonu
- "Zaten Hesabım Var" butonu → `SignIn` ekranı
- Google & Facebook kayıt

**Akış:**

1. Firebase Auth ile kullanıcı oluşturulur
2. `displayName` güncellenir
3. `sendEmailVerification()` ile doğrulama maili gönderilir
4. `VerifyAccount` ekranına yönlendirilir

### 🔐 Şifremi Unuttum (ResetPassword)

- E-posta adresi ile şifre sıfırlama maili gönderir
- Firebase Auth'un `sendPasswordResetEmail()` fonksiyonu kullanılır

---

## 3. Mail Doğrulama Ekranı (VerifyAccount)

### ⏰ Otomatik Kontrol

- **Her 3 saniyede bir** `user.reload()` yapılır
- `emailVerified` durumu kontrol edilir
- Doğrulandığı an otomatik `ProfilesScreen`'e geçiş

### 🔄 Manuel Kontrol

- "Devam Et" butonu ile manuel kontrol
- "Tekrar Gönder" butonu ile yeni doğrulama maili

### 💾 Firestore Kayıt

Doğrulama başarılı olduğunda:

```dart
await FirebaseFirestore.instance
    .collection("users")
    .doc(user.uid)
    .set({
      "displayName": user.displayName,
      "email": user.email,
      "verifiedAt": DateTime.now(),
    });
```

---

## 4. İlk Kez Girişte Tutorial

### 🎯 Tutorial Sistemi

- **İlk girişte** otomatik tutorial gösterilir
- `SharedPreferences` ile "görüldü" durumu kaydedilir
- `ProfilesScreen`'deki Help ikonu ile tekrar gösterilebilir

### 📱 Tutorial İçeriği

- Drawer menü kullanımı
- Profil kartı düzenleme
- Yeni profil ekleme
- Help butonu kullanımı

### 🔧 Teknik Detaylar

```dart
// Tutorial kontrolü
final hasSeenTutorial = prefs.getBool('hasSeenProfilesTutorial') ?? false;
if (!hasSeenTutorial) {
  _showTutorialCoachmar();
  await prefs.setBool('hasSeenProfilesTutorial', true);
}
```

---

## 5. ProfilesScreen

### 🏠 Ana Ekran

**İlk girişte (profil yokken):**

- Drawer menü
- Help ikonu
- **"Yeni Profil Ekle"** butonu

### 📝 Profil Formu

**Zorunlu alanlar:**

- Profil adı
- Boy (1-300 cm)
- Kilo (1-500 kg)
- Yaş (1-120)
- Cinsiyet
- Kan grubu

**Validasyon:**

- Boy: 1-300 cm
- Kilo: 1-500 kg
- Yaş: 1-120

### 💾 Veri Yapısı

```json
users/{uid}/
├── profiles: [
│   {
│     "id": "profile_id",
│     "name": "Profil Adı",
│     "height": 175,
│     "age": 30,
│     "weight": 70.5,
│     "gender": "Erkek",
│     "bloodType": "A+",
│     "chronicIllness": "Diyabet",
│     "isActive": true,
│     "createdAt": "2024-01-01T00:00:00Z",
│     "updatedAt": "2024-01-01T00:00:00Z"
│   }
│ ],
├── boy, yas, kilo, ... (legacy alanlar - geriye uyumluluk)
└── lastUpdated: timestamp
```

### 🎴 Profil Kartları

- Profil kartı tıklandığında düzenleme formu açılır
- Sağ üst "more" menüsü:
  - **Düzenle**: Profil bilgilerini güncelle
  - **Aktif Et**: Profili aktif yap (birden fazla profil varsa görünür)
  - **Sil**: Profili sil

### 🎯 Amaç

Aynı kullanıcının farklı aile bireylerini tanımlayıp tek dokunuşla aralarında geçiş yapabilmesi.

---

## 6. Drawer Menüsü

### 📋 Menü Öğeleri

- **Şikayet Başlat** → `HomeScreen`
- **Analiz Geçmişi** → `OldChatScreen`
- **Tahlil Yükle** → `PdfAnalysisScreen`
- **Profiller** → `ProfilesScreen`
- **Çıkış Yap** → Firebase Auth signOut

### 🔧 Teknik Detaylar

```dart
// Çıkış işlemi
await FirebaseAuth.instance.signOut();
Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const Opening()));
```

---

## 7. Şikayet Başlat (HomeScreen)

### 📊 Form Durumları

| Durum                  | Gösterilen Form                                                    |
| ---------------------- | ------------------------------------------------------------------ |
| **Aktif profil varsa** | Küçük profil kartı + "Şikayet / Süre / Mevcut İlaçlar" alanları    |
| **Profil yoksa**       | Geniş form: boy, kilo, yaş, cinsiyet, kan grubu + şikayet alanları |

### 🚀 "Şikayet Başlat" Akışı

1. **Form Validasyonu**

   - Tüm zorunlu alanlar kontrol edilir
   - Hata durumunda SnackBar gösterilir

2. **Veri Kaydetme**

   ```dart
   await FormService.saveComplaintWithProfile(
     formData: formData,
     complaintId: complaintId,
   );
   ```

3. **AI Soru Üretimi**

   ```dart
   final questions = await OpenAIService.getFollowUpQuestions(
     profileData,
     complaintData,
     userName,
   );
   ```

4. **İlk AI Mesajı**

   - Firestore `/messages` alt koleksiyonuna kaydedilir
   - `senderId: '2'` (AI) olarak işaretlenir

5. **Yönlendirme**
   - `OverviewScreen`'e yönlendirilir
   - Şikayet ID'si ve sorular parametre olarak geçilir

### 🎯 Tutorial Sistemi

- İlk kullanımda otomatik tutorial
- "Şikayet Başlat" butonuna odaklanır
- `SharedPreferences` ile durum takibi

---

## 8. Yapay Zeka ile Soru-Cevap (OverviewScreen)

### 🤖 AI Akışı

1. **İlk Değerlendirme**

   - AI eksik bilgileri madde madde sorulara çevirir
   - Selamlama + ilk soru tek mesajda birleştirilir

2. **Soru-Cevap Döngüsü**

   - Kullanıcı soruları yanıtlar
   - Her cevap Firestore'a kaydedilir
   - AI bir sonraki soruyu sorar

3. **Final Değerlendirme**
   - "Son" butonuna basıldığında `getFinalEvaluation()` çağrılır
   - Detaylı tıbbi değerlendirme tek parça mesaj olarak döner

### 💬 Mesaj Yapısı

```json
messages/
├── {
│     "text": "Mesaj içeriği",
│     "senderId": "1", // Kullanıcı
│     "sentAt": timestamp
│   },
├── {
│     "text": "AI mesajı",
│     "senderId": "2", // AI
│     "sentAt": timestamp
│   }
└── ...
```

### 📊 Progress Tracking

- Kalan soru sayısı gösterilir
- Progress bar ile ilerleme takibi
- Animasyonlu progress indicator

### 🎨 UI Özellikleri

- **DashChat2** kütüphanesi kullanılır
- Gerçek zamanlı mesaj görüntüleme
- Kullanıcı ve AI mesajları farklı renklerde
- Avatar'lar ve zaman damgaları

---

## 9. Analiz Geçmişi (OldChatScreen)

### 📋 Şikayet Listesi

- Firestore'dan çekilen her şikayet kart olarak listelenir
- `lastAnalyzed` tarihine göre sıralanır (en yeni üstte)

### 🎴 Kart Tasarımı

- **Avatar**: Renkli medical_services ikonu
- **Başlık**: Şikayet metni (tek satır)
- **Alt bilgi**: Son mesaj tarihi
- **Renk**: Şikayet ID'sine göre otomatik renk ataması

### 🔍 Detay Görüntüleme

Kart tıklandığında:

- `ChatHistoryDetailScreen`'e yönlendirilir
- Tam sohbet geçmişi gösterilir
- Mesajlar kronolojik sırada listelenir

### 📊 Boş Durum

- Henüz şikayet yoksa özel mesaj gösterilir
- "Henüz Mesaj Yok" ikonu ve metni

---

## 10. PDF Analizi (PdfAnalysisScreen)

### 📄 PDF Seçimi

- `FilePicker` ile cihazdan PDF seçimi
- Sadece `.pdf` uzantılı dosyalar kabul edilir
- Dosya boyutu ve format kontrolü

### 🔍 Analiz Akışı

1. **Metin Çıkarma**

   ```dart
   final fullText = await extractTextFromPdf(file);
   ```

2. **Metin Parçalama**

   ```dart
   final chunks = chunkText(fullText, chunkSize: 1000);
   ```

3. **AI Analizi**

   - Her parça GPT-4o'ya gönderilir
   - Tıbbi analiz isteği yapılır
   - Bölüm başlıkları `##` ile ayrılır

4. **Sonuç Yapısı**

   ```
   ## Genel Değerlendirme
   [AI analizi]

   ## Risk Faktörleri
   [Risk değerlendirmesi]

   ## Öneriler
   [Tıbbi öneriler]
   ```

### 💾 Analiz Saklama

- `PdfAnalysisService` ile analizler kaydedilir
- Dosya adı ve analiz sonucu saklanır
- Geçmiş analizler listelenebilir

### 📱 UI Özellikleri

- **Analiz Geçmişi** butonu → `SavedAnalysesScreen`
- **PDF Seç** butonu
- Loading indicator'ları
- Hata durumu yönetimi

### 🎯 Tutorial Sistemi

- İlk kullanımda otomatik tutorial
- Analiz geçmişi ve PDF seçimi butonlarına odaklanır

---

## 11. Teknik Detaylar

### 🔧 Firebase Yapılandırması

```dart
// main.dart
await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
await FirebaseAuth.instance.setPersistence(Persistence.LOCAL);
```

### 🔑 API Key Yönetimi

- `.env` dosyası ile API key'ler saklanır
- `flutter_dotenv` paketi kullanılır
- OpenAI API key güvenli şekilde yönetilir

### 📱 State Management

- **GetX** kullanılır (navigasyon için)
- **StreamBuilder** ile real-time veri dinleme
- **SharedPreferences** ile local storage

### 🎨 UI Kütüphaneleri

- **TutorialCoachMark**: Tutorial sistemi
- **DashChat2**: Sohbet arayüzü
- **FilePicker**: Dosya seçimi
- **Syncfusion PDF**: PDF işleme

### 🔄 Error Handling

- Try-catch blokları ile hata yönetimi
- SnackBar ile kullanıcı bilgilendirmesi
- Loading state'leri ile UX iyileştirmesi

---

## 12. Veri Yapısı

### 🔥 Firestore Koleksiyonları

```
users/{uid}/
├── displayName: string
├── email: string
├── verifiedAt: timestamp
├── profiles: [
│   {
│     id: string,
│     name: string,
│     height: number,
│     age: number,
│     weight: number,
│     gender: string,
│     bloodType: string,
│     chronicIllness: string,
│     isActive: boolean,
│     createdAt: timestamp,
│     updatedAt: timestamp
│   }
│ ],
├── complaints/{complaintId}/
│   ├── sikayet: string
│   ├── sure: string
│   ├── ilac: string
│   ├── createdAt: timestamp
│   ├── lastAnalyzed: timestamp
│   └── messages/
│       ├── {messageId}/
│       │   ├── text: string
│       │   ├── senderId: string (1: user, 2: AI)
│       │   └── sentAt: timestamp
│       └── ...
└── analyses/{analysisId}/
    ├── fileName: string
    ├── analysis: map
    └── createdAt: timestamp
```

### 📊 Legacy Veri Uyumluluğu

- Eski kullanıcılar için `boy`, `yas`, `kilo` alanları korunur
- Yeni profil sistemi ile uyumlu çalışır
- Geçiş sürecinde her iki yapı desteklenir

### 🔄 Veri Senkronizasyonu

- Real-time listener'lar ile anlık güncelleme
- Offline desteği Firebase ile sağlanır
- Conflict resolution otomatik yönetilir

---

## 🎯 Özet

Bu akış sayesinde kullanıcı:

1. **Kusursuz Açılış**: Gerçek zamanlı auth dinleme ile doğru yönlendirme
2. **Güvenli Doğrulama**: Mail doğrulama + 3 saniyelik polling
3. **Kişiselleştirilmiş Deneyim**: Çoklu profil sistemi
4. **Akıllı Analiz**: AI destekli soru-cevap akışı
5. **Hızlı Değerlendirme**: PDF analizi ile tahlil sonuçları
6. **Geçmiş Takibi**: Tüm veriler Firestore'da hiyerarşik saklanır

**Sonuç**: Kullanıcı, ilk temastan detaylı sağlık önerilerine kadar kesintisiz ve rehberli bir deneyim yaşar.
