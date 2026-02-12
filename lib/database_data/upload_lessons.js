const fs = require("fs");
const csv = require("csv-parser");
const admin = require("firebase-admin");

const serviceAccount = require("./serviceAccountKey.json");

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();

const sectionsMap = new Map();
const lessons = [];

// ================= HELPERS =================

function toBool(value) {
  if (!value) return false;
  return value.toString().toLowerCase() === "true";
}

function toNumber(value) {
  const n = Number(value);
  return isNaN(n) ? 0 : n;
}

function safeString(value) {
  return value && value.length > 0 ? value : null;
}

function normalizeLanguage(value) {
  return value ? value.toString().trim().toUpperCase() : "EN";
}

// ================= CSV READ =================

fs.createReadStream("lesson_data.csv")
  .pipe(
    csv({
      strict: false,
      skipLines: 0,
      mapHeaders: ({ header }) => header.trim(),
      mapValues: ({ value }) =>
        typeof value === "string" ? value.trim() : value,
    })
  )
  .on("data", (row) => {
    if (!row.lesson_id || !row.section) return;

    const lessonId = row.lesson_id.trim();
    const sectionName = row.section.trim();

    const sectionId = sectionName
      .toLowerCase()
      .replace(/[^a-z0-9 ]/g, "")
      .replace(/\s+/g, "_");

    // ---------- SECTION ----------
    if (!sectionsMap.has(sectionId)) {
      sectionsMap.set(sectionId, {
        title: sectionName,
        description: `Learning module on ${sectionName}`,
        order: sectionsMap.size + 1,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    }

    // ---------- DECISIONS ----------
    const questions = [];

    for (let i = 1; i <= 2; i++) {
      const qText = safeString(row[`decision_${i}_question`]);
      if (!qText) continue;

      const reflectionOptions = [
        safeString(row[`decision_${i}_reflection_option_1`]),
        safeString(row[`decision_${i}_reflection_option_2`]),
        safeString(row[`decision_${i}_reflection_option_3`]),
      ].filter(Boolean);

      const reflectionQuestion = safeString(
        row[`decision_${i}_reflection_question`]
      );

      questions.push({
        id: `D${i}`,
        type: "decision",
        question: qText,
        usesPaisa: toBool(row[`decision_${i}_uses_paisa`]),
        options: {
          a: {
            text: safeString(row[`decision_${i}_option_a`]),
            paisa: toNumber(row[`decision_${i}_option_a_paisa`]),
            outcome: safeString(row[`decision_${i}_outcome_a`]),
          },
          b: {
            text: safeString(row[`decision_${i}_option_b`]),
            paisa: toNumber(row[`decision_${i}_option_b_paisa`]),
            outcome: safeString(row[`decision_${i}_outcome_b`]),
          },
          c: {
            text: safeString(row[`decision_${i}_option_c`]),
            paisa: toNumber(row[`decision_${i}_option_c_paisa`]),
            outcome: safeString(row[`decision_${i}_outcome_c`]),
          },
        },
        ...(reflectionQuestion || reflectionOptions.length
          ? {
              reflection: {
                question: reflectionQuestion,
                options: reflectionOptions,
              },
            }
          : {}),
        weight: 1,
      });
    }

    // ---------- LESSON ----------
    lessons.push({
      lessonId,
      sectionId,
      language: normalizeLanguage(row.language),
      title: safeString(row.lesson_title),
      isMandatory: toBool(row.is_mandatory),
      points: toNumber(row.points),
      video: {
        url: safeString(row.video_url),
        durationSeconds: Math.round(toNumber(row.video_duration) * 60),
        script: row.video_script ? [row.video_script] : [],
      },
      quiz: { questions },
      ...(row.confidence_message || row.confidence_level
        ? {
            confidence: {
              message: safeString(row.confidence_message),
              level: safeString(row.confidence_level),
            },
          }
        : {}),
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  })
  .on("end", async () => {
    console.log(
      `Parsed CSV → Sections: ${sectionsMap.size}, Lessons: ${lessons.length}`
    );

    try {
      for (const [sectionId, sectionData] of sectionsMap) {
        await db.collection("sections").doc(sectionId).set(sectionData);
      }

      for (const lesson of lessons) {
        const { lessonId, ...lessonData } = lesson;
        await db.collection("lessons").doc(lessonId).set(lessonData);
      }

      console.log("✅ Lessons & sections uploaded successfully");
    } catch (err) {
      console.error("❌ Upload error:", err);
    }

    process.exit(0);
  })
  .on("error", (err) => {
    console.error("❌ CSV parse error:", err);
  });
