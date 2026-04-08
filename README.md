# Property Inspection App

A professional property inspection application built with Flutter, GetX, and modern UI design.

## 📱 Features

- ✅ Professional Login Screen
- ✅ Dashboard with Statistics
- ✅ Inspection List (List & Map View)
- ✅ Inspection Detail with Checklist
- ✅ Notifications
- ✅ Settings Screen
- ✅ GetX State Management
- ✅ Modern UI Design

## 📂 Project Structure

```
lib/
├── core/
│   ├── constants/
│   │   ├── app_colors.dart
│   │   └── app_constants.dart
│   └── theme/
│       └── app_theme.dart
├── presentation/
│   ├── bindings/
│   │   ├── auth_binding.dart
│   │   ├── dashboard_binding.dart
│   │   ├── inspection_binding.dart
│   │   ├── inspection_list_binding.dart
│   │   └── settings_binding.dart
│   ├── controllers/
│   │   ├── auth_controller.dart
│   │   ├── dashboard_controller.dart
│   │   ├── inspection_controller.dart
│   │   ├── inspection_list_controller.dart
│   │   └── settings_controller.dart
│   └── screens/
│       ├── login_screen.dart
│       ├── dashboard_screen.dart
│       ├── inspection_list_screen.dart
│       ├── inspection_detail_screen.dart
│       ├── notifications_screen.dart
│       └── settings_screen.dart
├── routes/
│   └── app_routes.dart
└── main.dart
```

## 🚀 Getting Started

1. Install dependencies:
```bash
flutter pub get
```

2. Run the app:
```bash
flutter run
```

## 📱 Screens

1. **Login** - Email/password authentication
2. **Dashboard** - Statistics and quick actions
3. **Inspection List** - View all inspections with filters
4. **Inspection Detail** - Complete inspection checklist
5. **Notifications** - View all notifications
6. **Settings** - App preferences and user profile

## 🎨 Design

- Modern gradient cards
- Professional color scheme
- Smooth animations
- Bottom navigation with FAB
- Toggle switches and dropdowns

## 📦 Dependencies

- `get` - State management
- `get_storage` - Local storage
- `image_picker` - Image selection
- `google_fonts` - Custom fonts

## 🔧 Configuration

Update constants in `lib/core/constants/app_constants.dart`

## 📄 License

Private project - All rights reserved
