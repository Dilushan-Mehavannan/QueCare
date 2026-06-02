# QueueCare - VS Code Developer Setup & Run Guide

Welcome to the **QueueCare** development repository. This workspace contains a full-stack real-time queue management system split into three main components:

1. **NestJS Backend**: High-performance REST & WebSocket server (`/`).
2. **React Dashboard**: Modern web dashboard for clinics built with Vite, React, and Tailwind CSS v4 (`/dashboard`).
3. **Mobile App**: Patients' cross-platform app built with Flutter (`/mobile`).

Follow this guide to get all services up and running smoothly in **VS Code**.

---

## 🛠️ Prerequisites & System Requirements

Ensure you have the following installed on your machine:
- **Node.js**: `v18.x` or `v20.x`+ (includes `npm`).
- **Flutter SDK**: `v3.x`+ (configured in your system `PATH`).
- **VS Code**: Latest version.

> [!WARNING]
> **Windows Developer Mode (Critical for Flutter)**
> On Windows systems, Flutter requires **Developer Mode** to be enabled to allow creating folder symlinks during plugin resolution.
> 
> **How to enable**: 
> 1. Open Windows Settings (`Win + I`).
> 2. Go to **Update & Security** > **For Developers** (or search "Developer settings").
> 3. Toggle **Developer Mode** to **On**.
> 4. Restart VS Code before running Flutter commands.

---

## 🔌 Recommended VS Code Extensions

For the best developer experience, search for and install these extensions in VS Code:

| Extension Name | Extension ID | Purpose |
| :--- | :--- | :--- |
| **Dart** | `dart-code.dart-code` | Syntax highlighting and analysis for Dart files. |
| **Flutter** | `dart-code.flutter` | Running, debugging, and hot-reloading the Mobile app. |
| **Tailwind CSS IntelliSense** | `bradlc.vscode-tailwindcss` | Autocomplete and preview for Tailwind CSS classes. |
| **ESLint** | `dbaeumer.vscode-eslint` | Code quality linting in Backend and Dashboard. |
| **Prettier - Code formatter** | `esbenp.prettier-vscode` | Code formatting. |

---

## 🚀 Running the Project inside VS Code (One-Click)

We have pre-configured native VS Code compound launchers so you can start all parts of the application simultaneously with a single keypress!

1. Open the **QueueCare** root folder in VS Code.
2. Click on the **Run and Debug** icon in the Activity Bar on the left side of VS Code (or press `Ctrl + Shift + D`).
3. In the dropdown at the top of the Debug sidebar, select:
   * 🌟 **`Run All Services (F5)`**: Starts the Backend dev server, React Dashboard, and Flutter Mobile App all together.
   * 💻 **`Run Web Stack (Backend + Dashboard)`**: Starts only the NestJS backend and Vite web dashboard.
4. Press the green **Start Debugging** arrow (or simply press `F5` on your keyboard).

VS Code will open active terminal logs for each service, showing you live console outputs, and will hook up hot-reloading for all three codebases!

---

## 💻 Running Services Manually via Terminal

If you prefer using separate terminal windows inside VS Code (`Ctrl + ~`), run the following commands:

### 1. NestJS Backend (`/`)
```bash
# Navigate to the root directory (if not already there)
# Install root/backend dependencies
npm install

# Setup your Environment variables
cp .env.example .env

# Run the developer watch server
npm run start:dev
```
* The backend will run at **`http://localhost:3000`** by default.

### 2. React Dashboard (`/dashboard`)
```bash
# Navigate to the dashboard directory
cd dashboard

# Install frontend dependencies
npm install

# Start the Vite development server
npm run dev
```
* The dashboard web interface will open at **`http://localhost:5173`**.

### 3. Patient Mobile App (`/mobile`)
```bash
# Navigate to the mobile directory
cd mobile

# Fetch Flutter dependencies
flutter pub get

# Run the application (Make sure you have an active emulator open or a physical device connected)
flutter run
```

---

## 🔑 Environment Setup (`.env`)

Before running the backend, ensure your `.env` file at the root of the workspace is configured correctly. A template is provided in `.env.example`:

```env
PORT=3000
DATABASE_URL="postgresql://username:password@localhost:5432/queue_care_db"
JWT_SECRET="your-super-secret-key"
REDIS_URL="redis://localhost:6379"
# Firebase config (if using push notifications / auth)
FIREBASE_PROJECT_ID="queuecare-app"
```

---

## 🔍 Troubleshooting Build Errors

### 1. "TypeScript JSX flags error during NestJS build"
If you run `npm run build` at the root and get JSX errors indicating frontend code is being scanned, make sure your root `tsconfig.json` contains:
```json
"exclude": ["node_modules", "dist", "dashboard", "mobile"]
```
*This has already been applied and verified in this workspace!*

### 2. "Tailwind CSS unknown utility class or PostCSS plugin errors"
Vite and PostCSS require `@tailwindcss/postcss` when compiling Tailwind CSS v4 in the dashboard. If you encounter Tailwind syntax issues:
1. Ensure `@tailwindcss/postcss` is installed in `dashboard/package.json` devDependencies.
2. Verify `dashboard/src/index.css` imports Tailwind using `@import "tailwindcss";` instead of the legacy `@tailwind` directives.
*This has already been applied and verified in this workspace!*

### 3. "Building with plugins requires symlink support" (Flutter on Windows)
This happens when Windows developer settings block symlink generation. Please enable **Developer Mode** in Windows as described in the [Prerequisites](#-prerequisites--system-requirements) section and restart VS Code.
