const functions = require("firebase-functions");
const admin = require("firebase-admin");
const axios = require("axios");

if (!admin.apps.length) {
  admin.initializeApp();
}

const auth = admin.auth();

exports.sendPasswordResetEmail = functions.https.onCall(async (data, context) => {
  try {
    console.log("Function triggered. Raw data received:", JSON.stringify(data));

    // **STEP 1: VALIDATE EMAIL**
    if (!data || !data.email || typeof data.email !== "string" || data.email.trim() === "") {
      throw new functions.https.HttpsError("invalid-argument", "A valid email is required.");
    }

    const email = data.email.trim().toLowerCase();

    // **STEP 2: SEND PASSWORD RESET EMAIL**
    await auth.generatePasswordResetLink(email);

    console.log(`Password reset link sent to: ${email}`);

    return { success: true, message: "Password reset email sent!" };

  } catch (error) {
    console.error("Error in sendPasswordResetEmail function:", error);
    throw new functions.https.HttpsError("internal", error.message || "Failed to send password reset email.");
  }
});

const POSTGRES_API_URL = `http://${global.ip}/users/update-password`;

exports.notifyPasswordReset = functions.https.onCall(async (data, context) => {
  const email = data.email;

  if (!email) {
    throw new functions.https.HttpsError('invalid-argument', 'Email is required.');
  }

  try {
    await axios.put(POSTGRES_API_URL, {
      email: email,
      new_password: "NEW_PASSWORD_PLACEHOLDER"
    });

    console.log(`PostgreSQL updated for user: ${email}`);

    return {success: true};
  } catch (error) {
    console.error("Error syncing password reset:", error);
    throw new functions.https.HttpsError('internal', 'Failed updating password reset.');
  }
});

exports.passwordResetWebhook = functions.https.onRequest(async (req, res) => {
  try {
    const email = req.body.email;
    const newPassword = req.body.new_password;

    if (!email || !newPassword) {
      console.log("Missing email or new password in request.");
      return res.status(400).json({ error: "Email and new password are required." });
    }

    console.log(`✅ Password reset detected for: ${email}`);

    // 🔥 Update Firebase password (optional, only if necessary)
    await auth.updateUser(email, { password: newPassword });

    // 🔥 Update PostgreSQL
    const response = await axios.put(POSTGRES_API_URL, {
      email: email,
      new_password: newPassword
    });

    console.log(`PostgreSQL updated for user: ${email}, Response:`, response.data);
    return res.status(200).json({ success: true, message: "Password updated in PostgreSQL" });
  } catch (error) {
    console.error("Error syncing password reset:", error.message);
    return res.status(500).json({ error: "Internal server error" });
  }
});