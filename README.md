# Swimming Trip 🏊‍♂️🌊

「Swimming Trip」は、日々の水泳トレーニングを「旅（Trip）」に変える、モチベーション維持に特化した水泳ログ＆トレーニング管理アプリです。

## 🌟 主な機能

### 1. マップ連動型進捗管理 (Swimming Trip)
設定した目標距離（週間・月間・年間）に応じて、マップ上の目的地を目指します。
- **ルート設定**: マップ上の任意の開始点と終了点を選択し、オリジナルの水泳ルートを作成。
- **旅の進捗**: 泳いだ距離に応じてアイコンがマップ上を移動。トレーニングの結果が視覚的な「旅の距離」として実感できます。

### 2. 高度なトレーニングメニュー管理
プロフェッショナルなトレーニングメニューの作成・保存・管理が可能です。
- **詳細設定**: 泳法（クロール、背泳ぎ、平泳ぎ、バタフライ、個人メドレー）、強度、セクション（Kick, Pull, Drill, Main等）、用具（フィン、パドル等）を細かく設定可能。
- **自動計算機能**:
  - **総距離**: メニュー全体の合計距離を自動算出。
  - **消費カロリー**: METs、体重、泳法、強度を組み合わせた高度なカロリー計算エンジンを搭載。

### 3. カレンダー & 統計
- **トレーニングログ**: 日々の泳いだ距離をカレンダーで管理。
- **目標管理**: 週間、月間、年間の目標達成度を可視化。
- **統計グラフ**: 過去のパフォーマンスをチャートで分析。

### 4. 多言語対応 (21言語)
日本語をはじめ、英語、スペイン語、フランス語、中国語など、世界中のスイマーが利用できるよう21の言語に対応しています。

## 📸 スクリーンショット

| マップ画面 | カレンダー画面 | メニュー管理 |
| :---: | :---: | :---: |
| ![Map](assets/images/map_screenshot.png) | ![Calendar](assets/images/calendar_screenshot.png) | ![Menu](assets/images/menu_screenshot.png) |

## 🛠 テックスタック

- **Framework**: [Flutter](https://flutter.dev/) (Dart)
- **State Management**: `StatefulWidget` & `SharedPreferences`
- **Maps**: [flutter_map](https://pub.dev/packages/flutter_map) (OpenStreetMap)
- **Localization**: [easy_localization](https://pub.dev/packages/easy_localization)
- **Charts**: [fl_chart](https://pub.dev/packages/fl_chart)
- **Animations**: [flutter_animate](https://pub.dev/packages/flutter_animate)
- **Database**: [shared_preferences](https://pub.dev/packages/shared_preferences) (Local storage)
- **Ads**: [google_mobile_ads](https://pub.dev/packages/google_mobile_ads)

## 🚀 はじめかた

### 依存関係のインストール
```bash
flutter pub get
```

### 実行
```bash
flutter run
```

## 📝 開発上の注意

### アセットの構成
- `assets/translations/`: 各言語の翻訳JSONファイル。
- `assets/images/`: スクリーンショットおよびアイコン。

### カロリー計算ロジック
本アプリは `lib/training_menu.dart` 内の独自のアルゴリズムを使用しており、泳法別のMETs値に基づいて、ユーザーの体重と運動強度を考慮した計算を行っています。

## 📄 ライセンス
このプロジェクトは [MIT License](LICENSE) のもとで公開されています。
