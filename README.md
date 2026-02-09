# Sambalam HR Management App

A comprehensive HR management application for marking attendance, salary management, onboarding management, PF, ESI calculation, and employee management.

## Features

- Splash Screen with authentication check
- Onboarding for new users
- Login with phone number and secure PIN
- Biometric authentication
- Company selection
- Attendance tracking with location and camera verification
- Leave management
- Salary management with breakdowns (TDS, PF, ESI)
- Role-based access (Employee, HR, Owner)

## Project Structure

### Frontend (Flutter)
- Mobile responsive design
- Authentication with phone number, PIN, and biometrics
- Location-based attendance tracking
- Camera integration for attendance verification

### Backend (Node.js)
- RESTful API endpoints
- Authentication and authorization
- Data processing and business logic

### Database (MongoDB)
- User management
- Company management
- Attendance records
- Salary information
- Leave management

## Architecture

The application follows a three-tier architecture:
1. Frontend (Flutter) - User interface
2. Middleware - API gateway and request processing
3. Backend - Business logic and database operations