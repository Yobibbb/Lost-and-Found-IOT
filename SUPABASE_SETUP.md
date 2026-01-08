# Supabase Image Storage Setup Guide

## ✅ Implementation Complete!

Your Lost & Found app now uses:
- **Firebase** for: Authentication, Database (Firestore), Chat messages
- **Supabase** for: Image storage ONLY (FREE, no credit card)

---

## 🚀 Setup Instructions:

### Step 1: Install Dependencies
Run this command:
```bash
flutter pub get
```

### Step 2: Create Supabase Account (FREE)
1. Go to https://supabase.com
2. Click "Start your project"
3. Sign up with GitHub or email (no credit card required)
4. Verify your email

### Step 3: Create New Project
1. Click "New Project"
2. Fill in:
   - **Name**: `lost-and-found` (or any name)
   - **Database Password**: Choose a strong password
   - **Region**: Select closest to you (e.g., Southeast Asia)
3. Click "Create new project"
4. Wait 2-3 minutes for setup

### Step 4: Get Your Credentials
1. In your project dashboard, click **Settings** (⚙️) in left sidebar
2. Click **API** tab
3. Copy these values:
   - **Project URL** (e.g., `https://xxxxx.supabase.co`)
   - **anon public** key (long string starting with `eyJ...`)

### Step 5: Update Your App
1. Open `lib/config/supabase_config.dart`
2. Replace:
```dart
static const String supabaseUrl = 'YOUR_SUPABASE_URL';
static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
```
With your values:
```dart
static const String supabaseUrl = 'https://xxxxx.supabase.co';
static const String supabaseAnonKey = 'eyJhbGc...your-long-key';
```

### Step 6: Create Storage Bucket
1. In Supabase dashboard, click **Storage** in left sidebar
2. Click **"New bucket"**
3. Fill in:
   - **Name**: `chat-images`
   - **Public bucket**: ✅ Check this (so images can be viewed)
4. Click "Create bucket"

### Step 7: Set Storage Policies
1. Click on the `chat-images` bucket
2. Click **"Policies"** tab
3. Click **"New policy"** under INSERT
4. Select **"Enable insert for all users"** template
5. Click **"Use this template"** → **"Save policy"**
6. Repeat for SELECT:
   - Click **"New policy"** under SELECT
   - Select **"Enable read access for all users"**
   - Click **"Use this template"** → **"Save policy"**

---

## ✅ Test Your Setup

1. Run your app: `flutter run`
2. Go to a chat
3. Tap the 📷 image icon
4. Select an image from gallery
5. Image should upload and display!

Check Supabase dashboard → Storage → chat-images to see uploaded images.

---

## 📊 Free Tier Limits

✅ **1 GB storage** (≈ 5,000 images)
✅ **2 GB bandwidth/month**
✅ **No credit card required**
✅ **No automatic charges**

Perfect for your Lost & Found app!

---

## 🔧 Troubleshooting

**Error: "Invalid Supabase URL"**
- Check you copied the full URL including `https://`

**Error: "Invalid API key"**
- Make sure you copied the **anon public** key (not the service_role key)

**Images not uploading**
- Check you created the bucket named exactly `chat-images`
- Verify bucket is set to **public**
- Check policies are enabled

**Need help?**
Check Supabase docs: https://supabase.com/docs/guides/storage

---

## 🎉 You're Done!

Your app now has FREE image storage with no credit card required!

Firebase = Auth + Database + Chat
Supabase = Images ONLY

Best of both worlds! 🚀
