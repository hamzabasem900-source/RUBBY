# 🥕 Bunny Carrot Adventure — خطوات التشغيل الفوري

## الملفات الموجودة في هذا المشروع

```
BunnyGame/
├── project.godot              ← ملف المشروع الرئيسي
├── scenes/
│   ├── MainMenu.tscn          ← الشاشة الرئيسية
│   ├── Instructions.tscn      ← شاشة التعليمات
│   ├── LevelMap.tscn          ← خريطة المستويات
│   ├── GameLevel.tscn         ← مشهد اللعب الرئيسي
│   ├── Player.tscn            ← الأرنب (اللاعب)
│   ├── Fox.tscn               ← الثعلب (عدو)
│   ├── Carrot.tscn            ← الجزرة
│   ├── Hole.tscn              ← الحفرة (خطر)
│   ├── Thorn.tscn             ← الشوك (خطر)
│   ├── WinScreen.tscn         ← شاشة الفوز
│   ├── GameOver.tscn          ← شاشة نهاية اللعبة
│   └── Settings.tscn          ← شاشة الاعدادات
└── scripts/
    ├── game_manager.gd
    ├── audio_manager.gd
    ├── player.gd
    ├── enemy_fox.gd
    ├── collectible_carrot.gd
    ├── hazard.gd
    ├── hud.gd
    ├── game_level.gd
    ├── main_menu.gd
    ├── instructions.gd
    ├── level_map.gd
    ├── settings_menu.gd
    ├── settings_manager.gd
    ├── win_screen.gd
    └── game_over.gd
```

---

## ✅ خطوات التشغيل (5 خطوات فقط)

### الخطوة 1 — افتح Godot 4.x
- افتح Godot Engine (الإصدار 4.x)
- اضغط **"Import"** أو **"Open"**
- اختر ملف `project.godot` من مجلد BunnyGame

### الخطوة 2 — تحقق من الـ AutoLoad
افتح: **Project → Project Settings → AutoLoad**

يجب أن ترى:
| Name         | Path                            |
|--------------|---------------------------------|
| GameManager  | res://scripts/game_manager.gd   |
| AudioManager | res://scripts/audio_manager.gd  |
| SettingsManager | res://scripts/settings_manager.gd |

إذا لم تكن موجودة، أضفهما يدويا.

### الخطوة 3 — تحقق من Input Map
افتح: **Project → Project Settings → Input Map**

يجب أن ترى هذه الأفعال:
- `move_right` → مفتاح D
- `move_left`  → مفتاح A
- `move_up`    → مفتاح W
- `move_down`  → مفتاح S

إذا لم تكن موجودة، أضفها يدويا.

### الخطوة 4 — تأكد من المشهد الرئيسي
افتح: **Project → Project Settings → Application → Run**

تأكد أن **Main Scene** = `res://scenes/MainMenu.tscn`

### الخطوة 5 — شغل اللعبة!
اضغط **F5** أو زر ▶ في أعلى الشاشة

---

## 🎮 طريقة اللعب
- **WASD** أو **أسهم لوحة المفاتيح** للتحرك
- اجمع الجزر البرتقالية = 10 نقاط
- اجمع الجزر الذهبية = 25 نقاط
- تجنب الثعالب والحفر والشوك
- ابدأ بـ 3 أرواح، كل إصابة = -1 روح

## 🏆 المستويات
| المستوى | الوقت | النقاط المطلوبة | الصعوبة |
|---------|-------|----------------|---------|
| 1       | 60 ث  | 80             | سهل    |
| 2       | 50 ث  | 120            | متوسط  |
| 3       | 40 ث  | 160            | صعب    |

---

## 🔊 إضافة الأصوات (اختياري)
ضع ملفات `.ogg` في مجلد `assets/audio/` بهذه الأسماء:
- `menu_music.ogg`
- `gameplay_music.ogg`
- `collect_carrot.ogg`
- `golden_collect.ogg`
- `damage.ogg`
- `button_click.ogg`
- `win.ogg`
- `game_over.ogg`

اللعبة تعمل بدون الأصوات ولن تتوقف.

---

## 🐛 مشاكل شائعة وحلولها

| المشكلة | الحل |
|---------|------|
| الأرنب لا يتحرك | تأكد من إضافة move_right/left/up/down في Input Map |
| خطأ "Node not found" | تأكد أن أسماء النودات في السكريبت تطابق أسماءها في المشهد |
| الـ AutoLoad لا يعمل | أضف GameManager و AudioManager في Project Settings → AutoLoad |
| اللعبة لا تبدأ | تأكد أن MainMenu.tscn هو Main Scene في Project Settings |
| الثعلب لا يتحرك | تأكد أن Gravity = 0 في Project Settings → Physics → 2D |
