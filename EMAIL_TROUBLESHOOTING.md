# Email Verification Troubleshooting Guide

If you're still not getting verification emails, follow this step-by-step:

## Step 1: Verify Firebase Auth is Enabled

1. Go to **Firebase Console** → Your Project "eshop-be005"
2. Click **Authentication** (under Build section)
3. Click **Sign-in method** tab
4. Check if **Email/Password** is **enabled** (toggle is ON)
5. If not enabled, click Email/Password and enable it

## Step 2: Configure Email Templates

1. In Firebase Authentication, click **Templates** tab
2. Look for **Email address verification** template
3. Click on it to view/edit
4. You should see template with:
   - Subject: Something like "Verify your email for Firebase Project"
   - Body: Should include a [LINK] placeholder

5. Make sure the template has:
   - [LINK] in the body (this becomes the verification link)
   - Professional subject line
   - Clear instructions

If template is missing, click **Send test email** and follow setup

## Step 3: Add Your App Domain to Firebase

1. In Authentication → Templates section
2. Check **"Your app's domain"** listed at bottom
3. If not there, you need to add it:
   - Click **Authorized domains** (in authentication settings)
   - Add your domain:
     - For web: `localhost:xxxxx` (your port)
     - For production: `yourdomain.com`

## Step 4: Check Gmail Spam Settings

The problem might be that Gmail is blocking automated emails:

1. Check your Gmail **Spam folder** for emails from `noreply@eshop-be005.firebaseapp.com`
2. If found:
   - Open the email
   - Click three dots → "Report not spam"
   - This trains Gmail to accept Firebase emails
3. Add `noreply@eshop-be005.firebaseapp.com` to contacts

## Step 5: Test Email Sending Directly

Test if Firebase can send emails at all:

1. In Firebase Console → Authentication
2. Select a user that doesn't have verified email
3. Click the user to open details
4. Click **⋮ (three dots)** menu
5. Click **Send reset password email**
6. Check if you receive a password reset email

**If you get the password reset email but not verification email:**
- The email template might be misconfigured
- Go back to Templates and reconfigure the verification email

## Step 6: Check Email Linking in App

Make sure your app domain is properly configured:

1. In Flutter code, check [firebase_options.dart](lib/firebase_options.dart)
2. Verify these values match your Firebase Console:
   ```dart
   authDomain: 'eshop-be005.firebaseapp.com',  // MUST exist
   projectId: 'eshop-be005',  // MUST be correct
   ```

3. If testing on localhost, add this to Firebase:
   - Go to Authentication → Authorized domains
   - Add: `localhost`
   - Click Save

## Step 7: Check Firebase Security Rules

1. Go to **Cloud Firestore** → **Rules** tab
2. Your rules should allow email verification writes:
   ```
   // Users can write to their own profile
   match /users/{userId} {
     allow read, write: if request.auth.uid == userId;
   }
   ```

3. Your rules should allow authentication metadata updates

## Step 8: Debug Code to See Actual Error

If none of the above works, modify [auth_service.dart](lib/auth/services/auth_service.dart) temporarily:

Find this line in the register method:
```dart
await newlyCreatedUser.sendEmailVerification();
```

Replace with:
```dart
try {
  await newlyCreatedUser.sendEmailVerification();
  print('✅ Email verification sent successfully');
} catch (emailError) {
  print('❌ Email sending failed: $emailError');
  throw Exception(
    'Email verification failed: ${emailError.toString()}',
  );
}
```

Then check **Flutter Console** for the actual error message.

## Step 9: Common Error Messages & Solutions

### "PERMISSION_DENIED"
- Your Firestore rules don't allow email updates
- **Fix**: Update Security Rules (see Step 7)

### "INVALID_SENDER"
- Firebase email template isn't configured
- **Fix**: Go to Authentication → Templates → Configure email

### "INVALID_TEMPLATE"
- Email template syntax error
- **Fix**: Delete and recreate the template

### "Network error"
- Internet connection issue
- **Fix**: Check your internet, try again

### "OPERATION_NOT_ALLOWED"
- Email/Password auth not enabled in Firebase
- **Fix**: Enable it in Authentication → Sign-in method

## Step 10: Manual Test

Do this to verify everything works:

1. Go to **Firebase Console** → **Authentication** → **Users**
2. Click **Create user** (top right)
3. Enter:
   - Email: `test@yourmail.com`
   - Password: `TestPassword123!`
4. Click **Create**
5. Go to **Cloud Firestore** → **users** collection
6. Add document with ID = user's UID and include:
   ```json
   {
     "email": "test@yourmail.com",
     "name": "Test User",
     "phone": "+254712345678",
     "role": "client",
     "emailVerified": false,
     "createdAt": <current timestamp>,
     "updatedAt": <current timestamp>,
     "isRoot": false
   }
   ```
7. Click the user in Authentication
8. Click ⋮ menu → **Send email verification**
9. **Check your email inbox**

If this works, your Firebase is configured correctly.

## Step 11: If Still No Email...

1. Check if Firebase project is on a paid plan
   - Go to Firebase Console → Project Settings
   - Check billing section
   - Spark plan might have limitations
   - **Solution**: Upgrade to Blaze plan (pay-as-you-go)

2. Check Firebase regional settings
   - Email might not be enabled in your region
   - **Solution**: Change region in Project Settings

3. Contact Firebase Support
   - Go to Firebase Console → help icon (?)
   - Click "Contact Support"
   - Describe the issue with your project

## Quick Checklist

- [ ] Email/Password auth enabled in Firebase
- [ ] Email verification template exists
- [ ] Your app domain added to authorized domains  
- [ ] Gmail spam check passed (not blocking Firebase)
- [ ] Authentication → Users shows the test user
- [ ] Manual email send test works
- [ ] Flutter app has correct firebase_options.dart
- [ ] No errors in Flutter console when registering
- [ ] Try signup process with real Gmail account

**After checking all of these, the email should arrive in your inbox within 30 seconds of signup.**

---

## Still Not Working?

Run this command in your project and share the output:

```bash
firebase auth:list --project=eshop-be005
```

This shows authenticated users and their verification status. If you see your test account there with `emailVerified: false`, then Firebase is working but email template has an issue.
