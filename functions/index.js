const functions = require("firebase-functions");
const admin = require("firebase-admin");

if (!admin.apps.length) {
  admin.initializeApp();
}

const auth = admin.auth();

exports.sendPasswordResetEmail = functions.https.onCall(async (data, context) => {
  try {
    console.log("🔍 Function triggered. Raw data received:", JSON.stringify(data));

    // **STEP 1: VALIDATE EMAIL**
    if (!data || !data.email || typeof data.email !== "string" || data.email.trim() === "") {
      throw new functions.https.HttpsError("invalid-argument", "A valid email is required.");
    }

    const email = data.email.trim().toLowerCase();

    // **STEP 2: SEND PASSWORD RESET EMAIL**
    await auth.generatePasswordResetLink(email);

    console.log(`✅ Password reset link sent to: ${email}`);

    return { success: true, message: "Password reset email sent!" };

  } catch (error) {
    console.error("🔥 Error in sendPasswordResetEmail function:", error);
    throw new functions.https.HttpsError("internal", error.message || "Failed to send password reset email.");
  }
});
