// Import các module theo chuẩn Gen 2 (v2)
const { onSchedule } = require("firebase-functions/v2/scheduler");
const admin = require('firebase-admin');
const axios = require('axios');
const nodemailer = require('nodemailer');

admin.initializeApp();

// ============================================================
// PHẦN CẤU HÌNH (ĐIỀN THÔNG TIN CỦA BẠN VÀO ĐÂY)
// ============================================================


const ONESIGNAL_APP_ID = "6ac28531-232a-43aa-a960-d1114cab6c8a";
const ONESIGNAL_API_KEY = "REST_API_KEY_LAY_TREN_WEB_ONESIGNAL"; // <-- ĐIỀN KEY VÀO ĐÂY

// Cấu hình Email (Nếu không dùng thì để trống)
const GMAIL_USER = "email_cua_ban@gmail.com";
const GMAIL_PASS = "mat_khau_ung_dung_16_ky_tu";

const transporter = nodemailer.createTransport({
    service: 'gmail',
    auth: { user: GMAIL_USER, pass: GMAIL_PASS }
});

// ============================================================
// HÀM CHÍNH (GEN 2 - SỬ DỤNG onSchedule)
// ============================================================
exports.checkDeadlines = onSchedule("every 15 minutes", async (event) => {
    const db = admin.database();
    const now = Date.now();
    const oneHourLater = now + 60 * 60 * 1000;
    const oneDayLater = now + 24 * 60 * 60 * 1000;

    const updates = {};
    const notifications = [];
    const emails = [];

    console.log("Bắt đầu kiểm tra deadline...");

    try {
        const usersSnapshot = await db.ref('users').once('value');
        if (!usersSnapshot.exists()) return;

        // 1. KIỂM TRA TASK CÁ NHÂN
        usersSnapshot.forEach(userSnap => {
            const userId = userSnap.key;
            const userData = userSnap.val();

            if (userData.personal_tasks) {
                Object.keys(userData.personal_tasks).forEach(taskId => {
                    const task = userData.personal_tasks[taskId];
                    // Check for 1 hour before deadline
                    if (shouldRemind(task, now, oneHourLater)) {
                        const msg = `⏰ Task cá nhân "${task.title}" sắp đến hạn trong 1 giờ!`;
                        if (userData.oneSignalId) notifications.push({ id: userData.oneSignalId, msg: msg });
                        if (userData.email && GMAIL_USER) emails.push({ to: userData.email, subject: "⏰ Deadline Task Cá Nhân", msg: msg });
                        updates[`users/${userId}/personal_tasks/${taskId}/isReminded`] = true;
                    }
                    // Check for 1 day before deadline
                    else if (shouldRemindDayBefore(task, now, oneDayLater)) {
                        const msg = `📅 Task cá nhân "${task.title}" sắp đến hạn trong 1 ngày!`;
                        if (userData.oneSignalId) notifications.push({ id: userData.oneSignalId, msg: msg });
                        if (userData.email && GMAIL_USER) emails.push({ to: userData.email, subject: "📅 Nhắc nhở Task Cá Nhân", msg: msg });
                    }
                });
            }
        });

        // 2. KIỂM TRA TASK DỰ ÁN
        const projectTasksSnapshot = await db.ref('tasks').once('value');
        if (projectTasksSnapshot.exists()) {
            projectTasksSnapshot.forEach(taskSnap => {
                const taskId = taskSnap.key;
                const task = taskSnap.val();

                if (task.assigneeId && task.assigneeId !== '') {
                    const assigneeData = usersSnapshot.child(task.assigneeId).val();
                    if (assigneeData) {
                        // Check for 1 hour before deadline
                        if (shouldRemind(task, now, oneHourLater)) {
                            const msg = `⏰ Dự án: Task "${task.title}" sắp hết hạn trong 1 giờ!`;
                            if (assigneeData.oneSignalId) notifications.push({ id: assigneeData.oneSignalId, msg: msg });
                            if (assigneeData.email && GMAIL_USER) emails.push({ to: assigneeData.email, subject: "⏰ Deadline Dự Án", msg: msg });
                            updates[`tasks/${taskId}/isReminded`] = true;
                        }
                        // Check for 1 day before deadline
                        else if (shouldRemindDayBefore(task, now, oneDayLater)) {
                            const msg = `📅 Dự án: Task "${task.title}" sắp hết hạn trong 1 ngày!`;
                            if (assigneeData.oneSignalId) notifications.push({ id: assigneeData.oneSignalId, msg: msg });
                            if (assigneeData.email && GMAIL_USER) emails.push({ to: assigneeData.email, subject: "📅 Nhắc nhở Task Dự Án", msg: msg });
                        }
                    }
                }
            });
        }

        // 3. CẬP NHẬT VÀ GỬI TIN
        if (Object.keys(updates).length > 0) {
            await db.ref().update(updates);
        }

        const pushPromises = notifications.map(n => sendPush(n.id, n.msg));
        const mailPromises = emails.map(e => sendMail(e.to, e.subject, e.msg));

        await Promise.all([...pushPromises, ...mailPromises]);
        console.log(`Hoàn tất. Đã gửi ${notifications.length} push, ${emails.length} email.`);

    } catch (error) {
        console.error("Lỗi khi chạy function:", error);
    }
});

// ============================================================
// CÁC HÀM PHỤ TRỢ
// ============================================================

function shouldRemind(task, now, threshold) {
    return task.dueDate &&
           task.status !== 'done' &&
           !task.isReminded &&
           task.dueDate > now &&
           task.dueDate <= threshold;
}

function shouldRemindDayBefore(task, now, threshold) {
    return task.dueDate &&
           task.status !== 'done' &&
           !task.isReminded &&
           task.dueDate > now &&
           task.dueDate <= threshold &&
           task.dueDate > now + 60 * 60 * 1000; // More than 1 hour away
}

async function sendPush(playerId, content) {
    try {
        await axios.post(
            'https://onesignal.com/api/v1/notifications',
            {
                app_id: ONESIGNAL_APP_ID,
                include_player_ids: [playerId],
                headings: { en: "Thông báo công việc" },
                contents: { en: content }
            },
            {
                headers: {
                    'Content-Type': 'application/json',
                    'Authorization': `Basic ${ONESIGNAL_API_KEY}`
                }
            }
        );
    } catch (e) {
        console.error("Lỗi gửi Push:", e.message);
    }
}

async function sendMail(to, subject, text) {
    if (!GMAIL_USER || !GMAIL_PASS) return;
    try {
        await transporter.sendMail({
            from: `"Scrum App Bot" <${GMAIL_USER}>`,
            to: to,
            subject: subject,
            text: text
        });
    } catch (e) {
        console.error("Lỗi gửi Email:", e.message);
    }
}