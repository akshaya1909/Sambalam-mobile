# Project Structure

```
sambalam/
├── frontend/                  # Flutter mobile application
│   ├── assets/                # Images, fonts, and other static files
│   │   ├── fonts/
│   │   ├── images/
│   │   └── logo/
│   ├── lib/
│   │   ├── api/               # API service classes
│   │   ├── config/            # App configuration
│   │   ├── models/            # Data models
│   │   ├── screens/           # UI screens
│   │   │   ├── splash/
│   │   │   ├── onboarding/
│   │   │   ├── auth/          # Authentication screens
│   │   │   │   ├── login/
│   │   │   │   ├── otp/
│   │   │   │   ├── secure_pin/
│   │   │   │   └── biometric/
│   │   │   ├── company/       # Company selection
│   │   │   ├── home/          # Main dashboard
│   │   │   ├── attendance/    # Attendance tracking
│   │   │   ├── leave/         # Leave management
│   │   │   ├── salary/        # Salary details
│   │   │   └── profile/       # User profile
│   │   ├── services/          # Business logic services
│   │   ├── utils/             # Utility functions
│   │   ├── widgets/           # Reusable UI components
│   │   └── main.dart          # Entry point
│   ├── pubspec.yaml           # Flutter dependencies
│   └── test/                  # Unit and widget tests
├── backend/                   # Node.js backend
│   ├── config/                # Server configuration
│   ├── controllers/           # Request handlers
│   ├── middleware/            # Custom middleware
│   ├── models/                # Database models
│   ├── routes/                # API routes
│   ├── services/              # Business logic
│   ├── utils/                 # Utility functions
│   ├── app.js                 # Express app setup
│   ├── server.js              # Server entry point
│   ├── package.json           # Node.js dependencies
│   └── tests/                 # API tests
└── database/                  # MongoDB schemas and migrations
    ├── schemas/
    └── migrations/
```