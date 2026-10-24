// web/fcm/firebase-messaging-sw.js
//
// سرویس‌ورکرِ پوشِ وب (Firebase Cloud Messaging).
//
// در پوشه‌ی fcm/ است تا scopeاش (/PersianballUIV3/fcm/) با سرویس‌ورکرِ خودِ
// فلاتر (/PersianballUIV3/) یکی نشود؛ دو سرویس‌ورکر با یک scope جای هم را
// می‌گیرند. برای دریافتِ پوش scope مهم نیست.
//
// پیکربندی از query stringِ همین فایل می‌آید (اپ موقعِ ثبت می‌فرستد) تا
// مقادیر فقط یک‌جا، در lib/firebase_options.dart، باشند.
importScripts('https://www.gstatic.com/firebasejs/10.13.2/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.13.2/firebase-messaging-compat.js');

const q = new URL(self.location.href).searchParams;
firebase.initializeApp({
  apiKey: q.get('apiKey'),
  appId: q.get('appId'),
  projectId: q.get('projectId'),
  messagingSenderId: q.get('messagingSenderId'),
});
const messaging = firebase.messaging();

// ریشه‌ی اپ: یک پوشه بالاتر از scopeِ همین سرویس‌ورکر
const appRoot = new URL('../', self.registration.scope).href;

// پیام‌های data-only را خودِ SDK نشان نمی‌دهد.
messaging.onBackgroundMessage((payload) => {
  if (payload.notification) return;
  const d = payload.data || {};
  if (!d.title) return;
  self.registration.showNotification(d.title, {
    body: d.body || '',
    icon: appRoot + 'icons/Icon-192.png',
    data: d,
  });
});

// لمسِ اعلان → صفحه‌ی مقصد. link کامل، یا route داخلی (#/order/2097).
self.addEventListener('notificationclick', (event) => {
  const d = (event.notification.data && (event.notification.data.FCM_MSG?.data || event.notification.data)) || {};
  const link = d.link || d.url || '';
  const route = d.route || (d.order_id ? '/order/' + d.order_id : d.product_id ? '/product/' + d.product_id : d.course_id ? '/course/' + d.course_id : '/notifications');
  const target = link.startsWith(appRoot) ? link : appRoot + '#' + (route.startsWith('/') ? route : '/' + route);
  event.notification.close();
  event.waitUntil((async () => {
    const wins = await clients.matchAll({ type: 'window', includeUncontrolled: true });
    for (const w of wins) {
      if (w.url.startsWith(appRoot)) { await w.focus(); return w.navigate ? w.navigate(target) : null; }
    }
    return clients.openWindow(target);
  })());
});
