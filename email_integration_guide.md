# Free Email OTP Integration Guide

You asked how to actually send the OTP emails for **free** and address the duplicate logic (`user.emailVerified` vs `isEmailVerified`).

## 1. Addressing the "Duplicate Logic"
Right now, the app checks `user.emailVerified || userModel.isEmailVerified`. We had to add `isEmailVerified` because **Flutter cannot manually set Firebase's built-in `emailVerified` field to true.** Firebase heavily locks this down.

To completely remove the duplicate logic and strictly use Firebase's built-in `emailVerified` field with our custom OTP, we **must** use a backend. A backend (like Node.js) can use the `Firebase Admin SDK` to forcefully update the user's Auth profile.

## 2. How to Send Emails for FREE

Here are the 2 best ways to do this without spending money:

### Option A: The "Serverless" API (100% Free, No Credit Card Needed) 🏆 RECOMMENDED
If you don't want to put a credit card on Firebase, you can host a tiny, free backend API on **Vercel** or **Render**.
1. **The Setup**: You create a simple Node.js API that uses `nodemailer` and a free **Gmail App Password**.
2. **How it works**: 
   - Flutter generates the OTP and sends it to `https://your-api.vercel.app/send-otp`.
   - The API sends the email.
   - When the user types the OTP in Flutter, Flutter tells the API it was correct.
   - The API uses `admin.auth().updateUser(uid, { emailVerified: true })` to officially verify them in Firebase!
3. **Cost**: **$0 forever.** Vercel is free, Gmail is free. No duplicate logic.

### Option B: Firebase "Trigger Email" Extension (Free Tier, but requires Blaze Plan)
Firebase has an official extension for this, but it requires you to upgrade your Firebase project to the **Blaze (Pay-as-you-go) plan**. 
1. **The Setup**: You upgrade to Blaze and install the "Trigger Email" extension.
2. **The Provider**: You create a free account on **Brevo** (300 free emails/day) or **SendGrid** (100 free emails/day) and link it to the extension.
3. **How it works**: Whenever Flutter saves an OTP, it also writes a document to the `mail` collection. The extension automatically sends it.
4. **Cost**: **$0**. Even though you are on the Blaze plan, you won't be charged unless you send over 2 million emails a month. *However, Google does require you to put a credit card on file to enable this plan.*
5. **Drawback**: You still have the "duplicate logic" (`isEmailVerified` in Firestore) because the extension only sends emails; it doesn't update Firebase Auth for you.

---

### What about sending directly from Flutter?
We *could* use a Flutter package like `mailer` to send the email directly using a Gmail password inside the app code. **Do not do this for production.** Anyone can extract your app's code, steal your Gmail password, and use your account to send spam.

### Next Steps
If you want **Option A** (which is 100% free, requires no credit card, and fixes the duplicate logic), I can write the exact Node.js code you need for the Vercel backend right now! Just let me know.
