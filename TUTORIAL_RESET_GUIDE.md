# Tutorial Sıfırlama Rehberi

## Özellik Açıklaması

Bu güncelleme ile kullanıcılar artık help butonuna basarak tüm tutorial'ları sıfırlayabilirler. Bu özellik şu ekranlarda mevcuttur:

- **Profiller Ekranı** (`profiles_screen.dart`)
- **Şikayet Ekranı** (`complaint_screen.dart`)

## Nasıl Çalışır?

1. Kullanıcı help butonuna (❓) basar
2. `TutorialService.resetAllTutorials()` fonksiyonu çağrılır
3. Tüm tutorial anahtarları SharedPreferences'tan silinir
4. Kullanıcıya bilgilendirme mesajı gösterilir
5. Mevcut sayfanın tutorial'ı hemen gösterilir

## Sıfırlanan Tutorial'lar

- `hasSeenHomeTutorial` - Ana sayfa tutorial'ı
- `hasSeenProfilesTutorial` - Profiller sayfası tutorial'ı
- `hasSeenComplaintTutorial` - Şikayet sayfası tutorial'ı
- `hasSeenPdfAnalysisTutorial` - PDF analiz sayfası tutorial'ı
- `hasSeenDrawerTutorial_*` - Drawer tutorial'ları (kullanıcıya özel)

## Yeni Servis: TutorialService

`lib/services/tutorial_service.dart` dosyasında yeni bir servis oluşturuldu:

### Ana Fonksiyonlar:

- `resetAllTutorials()` - Tüm tutorial'ları sıfırlar
- `resetTutorial(String tutorialName)` - Belirli bir tutorial'ı sıfırlar
- `hasSeenTutorial(String tutorialName)` - Tutorial'ın görülüp görülmediğini kontrol eder
- `markTutorialAsSeen(String tutorialName)` - Tutorial'ı görüldü olarak işaretler

## Kullanım Örneği

```dart
// Tüm tutorial'ları sıfırla
await TutorialService.resetAllTutorials();

// Belirli bir tutorial'ı sıfırla
await TutorialService.resetTutorial('home');

// Tutorial'ın görülüp görülmediğini kontrol et
bool hasSeen = await TutorialService.hasSeenTutorial('profiles');
```

## Kullanıcı Deneyimi

Help butonuna basıldığında:

1. Tüm tutorial'lar sıfırlanır
2. Mavi renkli bir SnackBar mesajı gösterilir: "Tüm tutorial'lar sıfırlandı. Uygulamayı yeniden başlatın veya diğer sayfalara gidip gelin."
3. Mevcut sayfanın tutorial'ı hemen gösterilir
4. Tooltip metni "Tüm Tutorial'ları Sıfırla" olarak güncellenir

## Gelecek Geliştirmeler

- Diğer ekranlara da help butonu eklenebilir
- Tutorial sıfırlama onay dialogu eklenebilir
- Belirli tutorial'ları seçerek sıfırlama özelliği eklenebilir
