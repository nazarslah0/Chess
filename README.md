# محلل وضعيات الشطرنج — Flutter

تطبيق Flutter حقيقي (بدون ميزة التعرف على الصور) يستخدم:

- [`chess`](https://pub.dev/packages/chess) — توليد نقلات قانونية 100%، FEN، SAN (منفذ Dart لمكتبة chess.js).
- [`stockfish`](https://pub.dev/packages/stockfish) — محرك **Stockfish 18 الحقيقي** مُصرَّف من المصدر عبر Dart FFI لأندرويد وiOS (لا محرك عشوائي أو وهمي).

## الميزات
- إعداد وضعية يدويًا بلوحة قطع + وضع لعب بقواعد شطرنج كاملة وصحيحة.
- تحليل حقيقي بـ Stockfish: العمق قابل للتعديل من 1 حتى 60 (غير مقيّد بـ30).
- عرض أفضل 3 نقلات (قابل للتغيير من 1 إلى 5) مع تحويلها لـ SAN ووسم النقلات الإجبارية "(إجبارية)".
- سهم يوضح أفضل نقلة على الرقعة، تمييز آخر نقلة والكش.
- قطع مرسومة حقيقية (Staunton-style، ليست رموز نصية) عبر `CustomPainter`.
- عدة ثيمات للرقعة وللقطع قابلة للاختيار من الأعلى.
- تحميل/عرض FEN.

## هيكل المشروع
```
lib/
  main.dart          # نقطة الدخول + شاشة رئيسية تجمع كل شيء
  models.dart         # GameState (يغلّف حزمة chess) + الثيمات
  engine_service.dart # غلاف بروتوكول UCI حول stockfish
  board_widget.dart   # رسم الرقعة + السهم
  piece_painter.dart  # رسم القطع الحقيقية (Staunton)
  panels.dart         # لوحة الإعداد، لوحة التحليل، قائمة النقلات
.github/workflows/build.yml  # بناء APK تلقائيًا على GitHub Actions
```

لا توجد مجلدات `android/` أو `ios/` في هذا الريبو — يتم توليدها تلقائيًا أثناء
البناء (عبر `flutter create --platforms=android,ios .`) لأن مخرجات هذا الأمر
خاصة بإصدار Flutter/الأدوات المحلية ولا يجب حفظها في المستودع.

## البناء والتشغيل محليًا
```bash
flutter create --platforms=android,ios .   # أول مرة فقط، أو إذا حذفت المجلدين
flutter pub get
flutter run
```

## البناء والتثبيت عبر GitHub (كما طلبت)
1. ارفع هذا المجلد إلى مستودع GitHub جديد وادفع (push) إلى فرع `main`.
2. سيعمل الـ workflow تلقائيًا (`.github/workflows/build.yml`) ويبني ملف APK.
3. من تبويب **Actions** في المستودع، افتح آخر تشغيل ناجح، وحمّل الملف المرفق
   باسم `chess-analyzer-apk` (Artifact) — داخله `app-release.apk` جاهز للتثبيت
   على أندرويد (فعّل "السماح بمصادر غير معروفة" لتثبيته يدويًا).
4. لإصدار رسمي مرفق تلقائيًا بصفحة Releases: أنشئ تاغ يبدأ بـ `v`، مثل:
   ```bash
   git tag v1.0.0
   git push origin v1.0.0
   ```
   سيُبنى APK ويُرفق تلقائيًا بإصدار جديد على GitHub Releases.

## ملاحظة أمانة مهمة
تمت كتابة هذا الكود بالاعتماد على التوثيق الرسمي المنشور لحزمتي `chess`
و`stockfish`. لا تتوفر لدي بيئة بها اتصال إنترنت لتشغيل
`flutter pub get` / `flutter analyze` / `flutter build` هنا والتحقق محليًا من
عدم وجود أي خطأ ترجمة قبل تسليمه لك — وهذا بالضبط ما سيفعله GitHub Actions
عند أول تشغيل. إن ظهر أي خطأ بسيط في البناء (مثل اختلاف اسم دالة أو نوع
إرجاع بين إصدارين من إحدى الحزمتين)، أرسل لي رسالة الخطأ من سجل Actions
وسأصلحه فورًا.

## معمارية Stockfish
`stockfish` يصرّف مصدر C++ الأصلي لـ Stockfish 18 أثناء البناء
عبر Dart FFI — أي محرك حقيقي متعدد القدرات يعمل محليًا بالكامل بلا إنترنت بعد
التثبيت، وليس نسخة WebAssembly كما في نسخة الويب.


## GitHub Actions

The repository is intentionally kept free of generated Android Gradle files. GitHub Actions generates a clean Android host using Flutter 3.47, installs dependencies, runs `flutter analyze` and `flutter test`, then produces a universal APK, ABI-split APKs, and an AAB.

Stockfish is provided by the `stockfish` Flutter package and runs on-device through native FFI; no Stockfish download is required when the app starts. The package version used here bundles Stockfish 18.

### Termux upload

```bash
git init
git branch -M main
git add .
git commit -m "Prepare Chess Analyzer for GitHub Actions"
git remote add origin https://github.com/YOUR_USERNAME/YOUR_REPO.git
git push -u origin main
```
