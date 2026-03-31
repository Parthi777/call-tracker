const { onDocumentCreated, onDocumentUpdated } = require("firebase-functions/v2/firestore");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore, Timestamp } = require("firebase-admin/firestore");

initializeApp();
const db = getFirestore();

/**
 * Triggered when a new call record is created.
 * Aggregates daily KPIs for the executive and writes to /kpi_daily.
 */
exports.aggregateKpiOnCallCreate = onDocumentCreated(
  "calls/{callId}",
  async (event) => {
    const callData = event.data?.data();
    if (!callData) return;

    await aggregateKpi(callData.executiveId, callData.timestamp);
  }
);

/**
 * Triggered when a call record is updated (e.g., status change after upload).
 * Re-aggregates KPIs.
 */
exports.aggregateKpiOnCallUpdate = onDocumentUpdated(
  "calls/{callId}",
  async (event) => {
    const callData = event.data?.after?.data();
    if (!callData) return;

    await aggregateKpi(callData.executiveId, callData.timestamp);
  }
);

/**
 * Aggregates all calls for an executive on a given date into a KPI snapshot.
 *
 * KPI definitions (from CLAUDE.md):
 *   Total Calls    — All recorded calls in period
 *   Incoming       — direction == "incoming"
 *   Outgoing       — direction == "outgoing"
 *   Missed         — Duration < 5s AND direction == "incoming"
 *   Avg Duration   — Sum of durations / Total calls (excluding missed)
 *   Talk Time      — Sum of all call durations
 *   Unique Contacts — Distinct phone numbers
 *   Peak Hour      — Hour-of-day with most calls
 */
async function aggregateKpi(executiveId, callTimestamp) {
  if (!executiveId || !callTimestamp) return;

  // Determine the date boundaries
  let callDate;
  if (callTimestamp instanceof Timestamp) {
    callDate = callTimestamp.toDate();
  } else if (callTimestamp._seconds) {
    callDate = new Date(callTimestamp._seconds * 1000);
  } else {
    callDate = new Date();
  }

  const startOfDay = new Date(callDate.getFullYear(), callDate.getMonth(), callDate.getDate());
  const endOfDay = new Date(startOfDay.getTime() + 24 * 60 * 60 * 1000);

  // Query all calls for this executive on this date
  const snapshot = await db
    .collection("calls")
    .where("executiveId", "==", executiveId)
    .where("timestamp", ">=", Timestamp.fromDate(startOfDay))
    .where("timestamp", "<", Timestamp.fromDate(endOfDay))
    .get();

  const calls = snapshot.docs.map((doc) => doc.data());

  // Compute KPIs
  const totalCalls = calls.length;
  const incoming = calls.filter((c) => c.direction === "incoming").length;
  const outgoing = calls.filter((c) => c.direction === "outgoing").length;
  const missed = calls.filter(
    (c) => (c.duration || 0) < 5 && c.direction === "incoming"
  ).length;

  const nonMissed = calls.filter((c) => (c.duration || 0) >= 5);
  const avgDuration =
    nonMissed.length > 0
      ? nonMissed.reduce((sum, c) => sum + (c.duration || 0), 0) / nonMissed.length
      : 0;

  const talkTime = calls.reduce((sum, c) => sum + (c.duration || 0), 0);

  const uniqueContacts = new Set(calls.map((c) => c.phoneNumber || "")).size;

  // Peak hour
  const hourCounts = {};
  for (const c of calls) {
    let ts = c.timestamp;
    if (ts instanceof Timestamp) ts = ts.toDate();
    else if (ts?._seconds) ts = new Date(ts._seconds * 1000);
    else continue;
    const hour = ts.getHours();
    hourCounts[hour] = (hourCounts[hour] || 0) + 1;
  }
  let peakHour = null;
  let maxCount = 0;
  for (const [hour, count] of Object.entries(hourCounts)) {
    if (count > maxCount) {
      maxCount = count;
      peakHour = parseInt(hour);
    }
  }

  // Write KPI snapshot
  const dateStr = `${startOfDay.getFullYear()}-${String(startOfDay.getMonth() + 1).padStart(2, "0")}-${String(startOfDay.getDate()).padStart(2, "0")}`;
  const docId = `${executiveId}_${dateStr}`;

  await db.collection("kpi_daily").doc(docId).set({
    executiveId,
    date: Timestamp.fromDate(startOfDay),
    totalCalls,
    incoming,
    outgoing,
    missed,
    avgDuration: Math.round(avgDuration * 10) / 10,
    talkTime,
    uniqueContacts,
    peakHour,
    updatedAt: Timestamp.now(),
  });

  console.log(`KPI aggregated: ${docId} — ${totalCalls} calls`);
}
