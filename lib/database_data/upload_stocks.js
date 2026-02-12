const admin = require("firebase-admin");
const fs = require("fs");
const csv = require("csv-parser");

admin.initializeApp({
  credential: admin.credential.cert(
    require("./serviceAccountKey.json") // 🔑 Firebase key
  ),
});

const db = admin.firestore();

async function uploadCSV() {
  const rows = [];

  fs.createReadStream("trading_data.csv")
    .pipe(csv())
    .on("data", (row) => rows.push(row))
    .on("end", async () => {
      for (const row of rows) {
        const symbol = row.symbol;

        // 1️⃣ STATIC STOCK DATA
        await db.collection("stocks").doc(symbol).set({
          symbol: symbol,
          name: row.name,
          sector: row.sector,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        // 2️⃣ MARKET PRICE DATA
        await db.collection("market_prices").doc(symbol).set({
          symbol: symbol,
          price: Number(row.price),
          change: Number(row.change),
          changePercent: Number(row.changePercent),
          source: "csv_seed",
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        console.log(`✅ Seeded ${symbol}`);
      }

      console.log("🚀 CSV upload completed");
      process.exit(0);
    });
}

uploadCSV();
