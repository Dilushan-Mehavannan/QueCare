# QueueCare - Healthcare Queue Management System

A robust backend built with NestJS, TypeORM, PostgreSQL, Bull (Redis), and Socket.IO.

## Features

- **Auth Module**: JWT-based authentication.
- **Users Module**: User profile management.
- **Clinics Module**: Clinic information and settings.
- **Appointments Module**: Booking and scheduling.
- **Queue Module**: Real-time queue management using Bull.
- **Notifications Module**: Real-time updates via Socket.IO.

## Prerequisites

- Node.js (v20+)
- Docker and Docker Compose
- Windows (with WSL2 or Docker Desktop)

## Getting Started

1. **Clone the repository**
2. **Setup environment variables**
   ```bash
   cp .env.example .env # Already created in this scaffold
   ```
3. **Start infrastructure (PostgreSQL & Redis)**
   ```bash
   docker-compose up -d
   ```
4. **Install dependencies**
   ```bash
   npm install
   ```
5. **Run the application**
   ```bash
   npm run start:dev
   ```

## Folder Structure

```text
src/
├── app.module.ts          # Root module configuration
├── main.ts                # Entry point
├── auth/                  # Authentication logic
├── users/                 # User management
├── clinics/               # Clinic data
├── appointments/          # Appointment scheduling
├── queue/                 # Queue processing (Bull)
├── notifications/         # Real-time updates (Socket.IO)
└── ...
```

## Docker

You can also run the entire application using Docker:

```bash
docker-compose build
docker-compose up
```
