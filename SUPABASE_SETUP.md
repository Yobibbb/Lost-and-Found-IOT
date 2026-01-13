# Supabase Setup Guide for Image Storage

## What Changed
Your app now uses **Supabase** for image storage instead of Firebase Storage. This provides:
- ✅ Faster uploads
- ✅ Better performance
- ✅ More generous free tier
- ✅ Public URLs without authentication

## Setup Steps

### 1. Create Supabase Project

1. Go to [https://supabase.com](https://supabase.com)
2. Sign up or log in
3. Click **"New Project"**
4. Fill in:
   - **Name**: `lost-and-found` (or any name)
   - **Database Password**: Create a strong password (save it!)
   - **Region**: Choose closest to you
5. Click **"Create new project"**
6. Wait 2-3 minutes for setup

### 2. Get Your Credentials

1. In your Supabase project dashboard
2. Click **Settings** (⚙️) in the left sidebar
3. Click **API**
4. Copy these values:
   - **Project URL** (looks like: `https://xxxxxxxxxxxxx.supabase.co`)
   - **anon/public key** (long string starting with `eyJhbGci...`)

### 3. Configure Your App

1. Open `lib/config/supabase_config.dart`
2. Replace the placeholder values:

```dart
class SupabaseConfig {
  static const String supabaseUrl = 'https://xxxxxxxxxxxxx.supabase.co'; // Paste your URL
  static const String supabaseAnonKey = 'eyJhbGci...'; // Paste your anon key
}
```

### 4. Create Storage Bucket

1. In Supabase dashboard, click **Storage** in left sidebar
2. Click **"New bucket"**
3. Set:
   - **Name**: `chat-images`
   - **Public bucket**: ✅ **Enable** (so images can be viewed)
4. Click **"Create bucket"**

### 5. Set Bucket Policies (Important!)

1. Click on your `chat-images` bucket
2. Click **"Policies"** tab
3. Click **"New policy"**
4. Select **"For full customization"**
5. Add these policies:

**Policy 1: Allow uploads from authenticated users**
```sql
CREATE POLICY "Allow authenticated uploads"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'chat-images');
```

**Policy 2: Allow public access to read**
```sql
CREATE POLICY "Allow public downloads"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'chat-images');
```

Or use the GUI:
- **Policy name**: `Allow authenticated uploads`
- **Allowed operation**: `INSERT`
- **Target roles**: `authenticated`

- **Policy name**: `Allow public downloads`
- **Allowed operation**: `SELECT`  
- **Target roles**: `public`

### 6. Install Dependencies

Run in terminal:
```bash
flutter pub get
```

### 7. Test It!

1. Run your app: `flutter run -d chrome`
2. Log in as a user
3. Start a chat
4. Click the image icon (📷)
5. Select an image
6. It should upload to Supabase!

## Verify Upload

To see uploaded images:
1. Go to Supabase Dashboard
2. Click **Storage** → **chat-images**
3. You'll see folders like: `chat_images/chatRoomId/timestamp_filename.jpg`

## Benefits of Supabase Storage

✅ **Free tier**: 1GB storage, 2GB bandwidth  
✅ **Fast**: Global CDN  
✅ **Public URLs**: Direct image links  
✅ **No authentication needed** for viewing  
✅ **Better performance** than Firebase Storage  

## Troubleshooting

**Error: "Invalid JWT"**
- Check your `supabaseAnonKey` is correct
- Make sure you copied the **anon/public** key, not the service key

**Error: "Permission denied"**
- Make sure bucket policies are set correctly
- Bucket should be public
- Check bucket name is exactly `chat-images`

**Images not showing**
- Verify bucket is public
- Check the image URL in database
- Open URL directly in browser to test

---

Your app is now ready to use Supabase for image storage! 🚀
