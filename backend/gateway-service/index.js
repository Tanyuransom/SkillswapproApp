const express = require('express');
const proxy = require('express-http-proxy');
const cors = require('cors');
const morgan = require('morgan');
const compression = require('compression');
const fs = require('fs');
const path = require('path');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 3000;

app.use(compression());
app.use(cors());
app.use(morgan('dev'));

// --- APK DOWNLOAD ROUTE ---
app.get('/api/download/apk', (req, res) => {
  const apkPath = path.join(__dirname, 'shared/skillswap.apk');
  console.log(`[Gateway] APK Download requested. Checking path: ${apkPath}`);
  
  if (fs.existsSync(apkPath)) {
    res.download(apkPath, 'skillswap.apk', (err) => {
      if (err) {
        console.error(`[Gateway] Error during APK download:`, err);
        if (!res.headersSent) {
          res.status(500).send('Error downloading file');
        }
      }
    });
  } else {
    console.warn(`[Gateway] APK Download failed: File not found at ${apkPath}`);
    res.status(404).send('APK file not found on the server. Please upload it first.');
  }
});

// --- APP VERSION ROUTE ---
app.get('/api/app-version', (req, res) => {
  res.json({
    versionCode: 2,
    versionName: '1.0.1',
    url: 'http://167.86.100.54:3000/api/download/apk'
  });
});

app.use((req, res, next) => {
  console.log(`[Gateway] ${req.method} ${req.url}`);
  next();
});

// Service URLs (Internal Docker Network)
const SERVICES = {
  auth: 'http://identity-service:3001',
  users: 'http://user-service:3003',
  courses: 'http://course-service:3002',
  categories: 'http://category-service:3004',
  shorts: 'http://shorts-service:3005',
  messaging: 'http://messaging-service:3006',
  notifications: 'http://notification-service:3007',
  enrollment: 'http://enrollment-service:3008',
  payments: 'http://payment-service:3009',
  verification: 'http://verification-service:3010',
  blogs: 'http://blog-service:3011',
  stats: 'http://stat-service:3012',
  likes: 'http://like-service:3014',
  comments: 'http://comment-service:3015',
  shares: 'http://share-service:3016',
  levels: 'http://level-service:3017',
};

// Route Definitions
const proxyOptions = {
  limit: '500mb',
  parseReqBody: false, // Transparently pipe the raw stream
  proxyReqPathResolver: (req) => {
    const resolvedPath = req.originalUrl.replace(/^\/api\/[^\/]+/, '') || '/';
    const finalPath = resolvedPath.startsWith('?') ? '/' + resolvedPath : resolvedPath;
    console.log(`[Gateway] Proxying ${req.method} ${req.originalUrl} -> ${finalPath}`);
    return finalPath;
  }
};

// --- BASE SERVICE ROUTES ---
app.use('/api/auth', proxy(SERVICES.auth, proxyOptions));
app.use('/api/users', proxy(SERVICES.users, proxyOptions));
app.use('/api/courses', proxy(SERVICES.courses, proxyOptions));
app.use('/api/categories', proxy(SERVICES.categories, proxyOptions));
app.use('/api/shorts', proxy(SERVICES.shorts, proxyOptions));
app.use('/api/messaging', proxy(SERVICES.messaging, proxyOptions));
app.use('/api/notifications', proxy(SERVICES.notifications, proxyOptions));
app.use('/api/enrollments', proxy(SERVICES.enrollment, proxyOptions));
app.use('/api/payments', proxy(SERVICES.payments, proxyOptions));
app.use('/api/verification', proxy(SERVICES.verification, proxyOptions));
app.use('/api/blogs', proxy(SERVICES.blogs, proxyOptions));
app.use('/api/stats', proxy(SERVICES.stats, proxyOptions));
app.use('/api/likes', proxy(SERVICES.likes, proxyOptions));
app.use('/api/comments', proxy(SERVICES.comments, proxyOptions));
app.use('/api/shares', proxy(SERVICES.shares, proxyOptions));
app.use('/api/levels', proxy(SERVICES.levels, proxyOptions));

const server = app.listen(PORT, () => {
  console.log(`🚀 API Gateway running on port ${PORT}`);
});
server.timeout = 10 * 60 * 1000; // 10 minutes timeout for file uploads
