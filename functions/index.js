// Import các module theo chuẩn Gen 2 (v2)
const { onSchedule } = require("firebase-functions/v2/scheduler");
const admin = require("firebase-admin");
const axios = require("axios");
const nodemailer = require("nodemailer");

admin.initializeApp();

const ONESIGNAL_APP_ID = "6ac28531-232a-43aa-a960-d1114cab6c8a";
const ONESIGNAL_API_KEY =
  "os_v2_app_nlbikmjdfjb2vkla2eiuzk3mrktlzfkhs45uv5nfxgmk4qa6bcaih57lmaglff3ijbmekrcyoy7zx7nc24repkicstco3wct5bzxyey"; // <-- ĐIỀN KEY VÀO ĐÂY

const GMAIL_USER = "";
const GMAIL_PASS = "";

const transporter = nodemailer.createTransport({
  service: "gmail",
  auth: { user: GMAIL_USER, pass: GMAIL_PASS },
});

const { onRequest } = require("firebase-functions/v2/https");

exports.testDeadlinesNow = onRequest(async (req, res) => {
  console.log("=== MANUAL TEST: Chạy checkDeadlines NGAY LẬP TỨC ===");
  await checkDeadlines({});
  res.send("Test hoàn tất! Kiểm tra Cloud Logging và push trên điện thoại.");
});

exports.checkDeadlines = onSchedule("every 15 minutes", async (event) => {
  const db = admin.database();
  const now = Date.now();
  const oneHourLater = now + 60 * 60 * 1000; // 1 giờ sau
  const oneDayLater = now + 24 * 60 * 60 * 1000; // 1 ngày sau

  const updates = {};
  const notifications = [];
  const emails = [];

  console.log(
    "Bắt đầu kiểm tra deadline... Thời gian hiện tại:",
    new Date(now).toISOString()
  );

  try {
    const usersSnapshot = await db.ref("users").once("value");
    if (!usersSnapshot.exists()) return;

    // 1. KIỂM TRA TASK CÁ NHÂN (personal_tasks)
    usersSnapshot.forEach((userSnap) => {
      const userId = userSnap.key;
      const userData = userSnap.val();

      if (userData.personal_tasks) {
        Object.keys(userData.personal_tasks).forEach((taskId) => {
          const task = userData.personal_tasks[taskId];

          // Nhắc 1 giờ trước hạn
          if (shouldRemind(task, now, oneHourLater)) {
            const msg = `⏰ Task cá nhân "${task.title}" sắp đến hạn trong 1 giờ nữa!`;
            notifications.push({ externalId: userId, msg }); // Dùng userId làm external_id
            if (userData.email && GMAIL_USER) {
              emails.push({
                to: userData.email,
                subject: "⏰ Deadline Task Cá Nhân",
                msg,
              });
            }
            updates[
              `users/${userId}/personal_tasks/${taskId}/isReminded`
            ] = true;
          }
          // Nhắc 1 ngày trước hạn
          else if (shouldRemindDayBefore(task, now, oneDayLater)) {
            const msg = `📅 Task cá nhân "${task.title}" sắp đến hạn trong 1 ngày nữa!`;
            notifications.push({ externalId: userId, msg });
            if (userData.email && GMAIL_USER) {
              emails.push({
                to: userData.email,
                subject: "📅 Nhắc nhở Task Cá Nhân",
                msg,
              });
            }
          }
        });
      }
    });

    // 2. KIỂM TRA TASK DỰ ÁN (tasks trong /tasks)
    const projectTasksSnapshot = await db.ref("tasks").once("value");
    if (projectTasksSnapshot.exists()) {
      projectTasksSnapshot.forEach((taskSnap) => {
        const taskId = taskSnap.key;
        const task = taskSnap.val();

        if (task.assigneeId && task.assigneeId !== "") {
          const assigneeId = task.assigneeId;
          const assigneeData = usersSnapshot.child(assigneeId).val();

          if (assigneeData) {
            // Nhắc 1 giờ trước hạn
            if (shouldRemind(task, now, oneHourLater)) {
              const msg = `⏰ Task dự án "${task.title}" (Dự án: ${task.projectId}) sắp hết hạn trong 1 giờ!`;
              notifications.push({ externalId: assigneeId, msg });
              if (assigneeData.email && GMAIL_USER) {
                emails.push({
                  to: assigneeData.email,
                  subject: "⏰ Deadline Task Dự Án",
                  msg,
                });
              }
              updates[`tasks/${taskId}/isReminded`] = true;
            }
            // Nhắc 1 ngày trước hạn
            else if (shouldRemindDayBefore(task, now, oneDayLater)) {
              const msg = `📅 Task dự án "${task.title}" (Dự án: ${task.projectId}) sắp hết hạn trong 1 ngày!`;
              notifications.push({ externalId: assigneeId, msg });
              if (assigneeData.email && GMAIL_USER) {
                emails.push({
                  to: assigneeData.email,
                  subject: "📅 Nhắc nhở Task Dự Án",
                  msg,
                });
              }
            }
          }
        }
      });
    }

    // 3. CẬP NHẬT DATABASE VÀ GỬI THÔNG BÁO
    if (Object.keys(updates).length > 0) {
      await db.ref().update(updates);
      console.log("Đã cập nhật isReminded cho các task sắp hết hạn");
    }

    // Gửi push notification dùng external_user_id
    const pushPromises = notifications.map((n) =>
      sendPush(n.externalId, n.msg)
    );

    // Gửi email nếu có
    const mailPromises = emails.map((e) => sendMail(e.to, e.subject, e.msg));

    await Promise.all([...pushPromises, ...mailPromises]);
    console.log(
      `Hoàn tất: Đã gửi ${notifications.length} push notification và ${emails.length} email.`
    );
  } catch (error) {
    console.error("Lỗi khi chạy function checkDeadlines:", error);
  }
});

function shouldRemind(task, now, threshold) {
  return (
    task.dueDate &&
    task.status !== "done" &&
    !task.isReminded &&
    task.dueDate > now &&
    task.dueDate <= threshold
  );
}

function shouldRemindDayBefore(task, now, threshold) {
  return (
    task.dueDate &&
    task.status !== "done" &&
    !task.isReminded &&
    task.dueDate > now &&
    task.dueDate <= threshold &&
    task.dueDate > now + 60 * 60 * 1000
  ); // More than 1 hour away
}

async function sendPush(externalUserId, content) {
  if (!externalUserId) return { ok: false, reason: "no_external_id" };

  const payload = {
    app_id: ONESIGNAL_APP_ID,
    include_external_user_ids: [externalUserId],
    headings: { en: "⏰ Nhắc deadline" },
    contents: { en: content },

    // 👇 dùng cho Flutter deep link
    data: {
      type: "deadline",
      screen: "task_detail",
    },
  };

  try {
    const res = await axios.post(
      "https://onesignal.com/api/v1/notifications",
      payload,
      {
        headers: {
          "Content-Type": "application/json",
          Authorization: `Bearer ${ONESIGNAL_API_KEY}`,
        },
        timeout: 8000,
      }
    );

    return { ok: true, id: res.data.id };
  } catch (err) {
    const errData = err.response?.data || err.message;
    console.error(`❌ Push fail [${externalUserId}]`, errData);

    // retry 1 lần cho chắc
    try {
      await new Promise((r) => setTimeout(r, 1000));
      await axios.post("https://onesignal.com/api/v1/notifications", payload, {
        headers: {
          "Content-Type": "application/json",
          Authorization: `Bearer ${ONESIGNAL_API_KEY}`,
        },
      });
      return { ok: true, retry: true };
    } catch (e2) {
      return { ok: false, reason: "retry_failed" };
    }
  }
}

async function sendMail(to, subject, text) {
  if (!GMAIL_USER || !GMAIL_PASS) return;
  try {
    await transporter.sendMail({
      from: `"Scrum App Bot" <${GMAIL_USER}>`,
      to: to,
      subject: subject,
      text: text,
    });
  } catch (e) {
    console.error("Lỗi gửi Email:", e.message);
  }
}
