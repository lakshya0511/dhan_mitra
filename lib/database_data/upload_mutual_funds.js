const admin = require("firebase-admin");
const fs = require("fs");
const csv = require("csv-parser");

const serviceAccount = require("./serviceAccountKey.json");

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();

fs.createReadStream("mutual_fund_data.csv")
  .pipe(csv())
  .on("data", async (row) => {
    const fundId = row.fundId;

    await db.collection("mf_nav").doc(fundId).set({
      nav: parseFloat(row.nav),
      change: parseFloat(row.change),
      changePercent: parseFloat(row.changePercent),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    console.log("Uploaded:", fundId);
  })
  .on("end", () => {
    console.log("Upload complete.");
  });
