# Firebase Console Kontrol Listesi - ApiException: 10 Hatası

## 🔥 Acil Kontroller (ApiException: 10 için)

### 1. Firebase Console > Authentication > Sign-in method

1. **Google'ı etkinleştirin:**
   - ✅ Google provider'ı açın
   - ✅ Project support email seçin
   - ✅ Web SDK configuration'da client ID'yi kontrol edin

### 2. Firebase Console > Project Settings > General

1. **SHA-1 sertifika parmak izlerini kontrol edin:**
   - Mevcut: `24099334a55568f8583cb0313e06ae32e74714a4`
   - Yeni: `c1d970948a07ab9f278f3bdc4b4ebdc840f57f94`
2. **Package name uyumluluğu:**
   - `build.gradle.kts`: `com.zgr.doktorumOnline` ✅
   - `google-services.json`: `com.zgr.doktorumOnline` ✅

### 3. Google Cloud Console > APIs & Services > Credentials

1. **OAuth 2.0 Client IDs kontrol edin:**

   - Android: `325913484637-fbvot6mbudvs9okvko4dnianv0te85vm.apps.googleusercontent.com`
   - Web: `325913484637-80fha91qrunaiafu8ld2jidennuvovhg.apps.googleusercontent.com`

2. **OAuth consent screen:**
   - ✅ Publishing status: Testing veya In production
   - ✅ Test users ekleyin (eğer Testing modundaysa)

## 🛠️ Çözüm Adımları

### Adım 1: Firebase Console'da Google Provider'ı Yeniden Yapılandırın

1. Firebase Console > Authentication > Sign-in method
2. Google'ı devre dışı bırakın
3. Tekrar etkinleştirin
4. Project support email seçin

### Adım 2: SHA-1 Parmak İzini Güncelleyin

1. Firebase Console > Project Settings > General
2. "Add fingerprint" butonuna tıklayın
3. Debug SHA-1: `24099334a55568f8583cb0313e06ae32e74714a4`
4. Release SHA-1: `c1d970948a07ab9f278f3bdc4b4ebdc840f57f94`

### Adım 3: Google Cloud Console'da OAuth Consent Screen

1. Google Cloud Console > APIs & Services > OAuth consent screen
2. Publishing status'u kontrol edin
3. Test users ekleyin (eğer Testing modundaysa)

### Adım 4: Uygulamayı Yeniden Build Edin

```bash
flutter clean
flutter pub get
flutter run
```

## 🚨 ApiException: 10 Hata Kodları

| Kod   | Anlam             | Çözüm                               |
| ----- | ----------------- | ----------------------------------- |
| 10    | DEVELOPER_ERROR   | SHA-1 veya package name uyumsuzluğu |
| 7     | NETWORK_ERROR     | İnternet bağlantısı sorunu          |
| 12501 | SIGN_IN_CANCELLED | Kullanıcı iptal etti                |
| 12500 | SIGN_IN_FAILED    | Genel hata                          |

## 📱 Test Önerileri

1. **Physical device kullanın** (emulator'da sorun olabilir)
2. **Google Play Services güncel olmalı**
3. **Test hesabı ile deneyin**
4. **İnternet bağlantısını kontrol edin**

## 🔍 Debug Komutları

```bash
# SHA-1 almak için (Windows):
keytool -list -v -keystore "%USERPROFILE%\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android

# SHA-1 almak için (macOS/Linux):
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
```

## 📞 Hala Sorun Varsa

1. **Firebase Console'da Authentication > Users** bölümünü kontrol edin
2. **Google Cloud Console'da OAuth consent screen** durumunu kontrol edin
3. **Test cihazında Google hesabını çıkış yapıp tekrar giriş yapın**
4. **Uygulamayı tamamen kapatıp yeniden açın**
