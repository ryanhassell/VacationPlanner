const functions = require("firebase-functions");
const admin = require("firebase-admin");
const nodemailer = require("nodemailer");

admin.initializeApp();
const db = admin.firestore();

const transporter = nodemailer.createTransport({
  service: "gmail",
  auth: {
    user: "your-email@gmail.com",
    pass: "your-email-password",
  },
});

exports.sendOtpEmail = functions.https.onCall(async (data, context) => {
  const email = data.email;
  const otp = Math.floor(100000 + Math.random() * 900000).toString(); // 6-digit OTP

  await db.collection("otps").doc(email).set({
    otp: otp,
    expiresAt: admin.firestore.Timestamp.fromDate(new Date(Date.now() + 5 * 60000)), // Expires in 5 mins
  });

  const mailOptions = {
    from: "your-email@gmail.com",
    to: email,
    subject: "Your One-Time Password (OTP)",
    text: `Your OTP code is: ${otp}. It will expire in 5 minutes.`,
  };

  await transporter.sendMail(mailOptions);
  return {success: true, message: "OTP sent!"};
});
