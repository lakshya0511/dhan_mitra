const admin = require("firebase-admin");
const fs = require("fs");
const csv = require("csv-parser");

admin.initializeApp({
  credential: admin.credential.cert(require("./serviceAccountKey.json"))
});

const db = admin.firestore();

async function uploadRewards() {
  fs.createReadStream("rewards.csv")
    .pipe(csv())
    .on("data", async (row) => {
      await db.collection("rewards").doc(row.id).set({
        title: row.title,
        description: row.description,
        costPoints: parseInt(row.costPoints),
        paisaReward: parseInt(row.paisaReward),
        active: row.active === "true",
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      console.log("Uploaded:", row.id);
    });
}

uploadRewards();
