# App Icon Setup Guide

## Step 1: Prepare Your Icon Image

You need to create or provide an app icon image with these requirements:

### Main Icon (app_icon.png)
- **Size**: 1024x1024 pixels (square)
- **Format**: PNG with transparency (if needed)
- **Content**: Your app logo/icon
- **Location**: `assets/icon/app_icon.png`

### Adaptive Icon Foreground (app_icon_foreground.png) - Optional
- **Size**: 1024x1024 pixels (square)
- **Format**: PNG with transparency
- **Content**: Foreground part of your icon (will be placed on colored background)
- **Location**: `assets/icon/app_icon_foreground.png`
- **Note**: If you don't provide this, the main icon will be used

## Step 2: Add Your Icon Files

1. Create or download your app icon (1024x1024 PNG)
2. Save it as `assets/icon/app_icon.png`
3. (Optional) Create adaptive icon foreground as `assets/icon/app_icon_foreground.png`

## Step 3: Customize Colors (Optional)

Edit `pubspec.yaml` and change:
- `adaptive_icon_background: "#2196F3"` - Change to your preferred background color (hex code)

## Step 4: Generate Icons

Run these commands:

```bash
flutter pub get
flutter pub run flutter_launcher_icons
```

This will automatically generate all required icon sizes for:
- Android (all densities: mdpi, hdpi, xhdpi, xxhdpi, xxxhdpi)
- iOS (all required sizes)

## Step 5: Test

1. Clean build: `flutter clean`
2. Run the app: `flutter run`
3. Check the app icon on your device/emulator

## Icon Design Tips

- **Simple and recognizable**: Icons should be clear even at small sizes
- **Square format**: Design in a square canvas, but content can be circular or have padding
- **High contrast**: Ensure your icon stands out on various backgrounds
- **No text**: Avoid small text that won't be readable at small sizes
- **Centered**: Keep important elements centered

## Quick Icon Creation Tools

- **Online**: [AppIcon.co](https://www.appicon.co/), [IconKitchen](https://icon.kitchen/)
- **Design Tools**: Figma, Adobe Illustrator, Canva
- **AI Tools**: DALL-E, Midjourney (generate and export as PNG)

## Current Configuration

- **Android**: ✅ Enabled
- **iOS**: ✅ Enabled
- **Adaptive Icon Background**: Blue (#2196F3)
- **Main Icon Path**: `assets/icon/app_icon.png`
- **Foreground Icon Path**: `assets/icon/app_icon_foreground.png` (optional)

## Troubleshooting

**Icons not updating?**
- Run `flutter clean`
- Delete `build/` folder
- Regenerate icons: `flutter pub run flutter_launcher_icons`
- Rebuild: `flutter run`

**Icon looks blurry?**
- Make sure source image is exactly 1024x1024 pixels
- Use PNG format (not JPG)
- Don't compress the image too much

**Adaptive icon not working?**
- Ensure foreground image has transparency
- Check that background color is a valid hex code
- Verify both files exist in `assets/icon/` folder

