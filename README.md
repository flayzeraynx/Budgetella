# FinVault: Privacy-First Personal Finance Tracker

FinVault is a modern, privacy-focused personal finance tracker designed to help you manage your finances without compromising your data. Unlike traditional finance apps that store your sensitive financial information on remote servers, FinVault works entirely offline and stores all data locally on your device.

![FinVault App](public/icon-512.png)

## 🔒 Privacy-First Approach

- **100% Local Storage**: All your financial data stays on your device
- **No Cloud Sync**: Your data never leaves your device without your explicit action
- **No Tracking**: No analytics or user tracking of any kind
- **Open Source**: Transparent codebase you can inspect and verify

## ✨ Key Features

- **Dashboard Overview**: Get a quick snapshot of your income, expenses, and financial trends
- **Transaction Management**: Easily add, edit, and categorize your income and expenses
- **Category Customization**: Create and manage custom categories for better organization
- **Data Visualization**: View your financial data through intuitive charts and graphs
- **Data Export/Import**: Backup and restore your data whenever you need
- **Google Drive Integration**: Optionally sync your data with Google Drive for cross-device access
- **Server Sync**: Store your data on your own web server for access from any device
- **Responsive Design**: Works seamlessly on desktop, tablet, and mobile devices
- **Dark/Light Mode**: Choose the theme that's easiest on your eyes

## 📱 User Interface

### Dashboard
The dashboard provides a quick overview of your financial status:
- Income and expense summaries
- Recent transactions
- Financial trends visualization
- Personalized savings tips

### Transactions
The transactions page allows you to:
- View all your transactions in a sortable, filterable table
- Search for specific transactions
- Add new transactions with detailed information
- Edit or delete existing transactions
- Categorize transactions for better organization

### Settings
Customize your experience with various settings:
- Manage transaction categories
- Select your preferred currency
- Connect to Google Drive for data sync
- Set up server sync with your own hosting
- Import or export your data
- Toggle between light and dark themes

## 🚀 Getting Started

### Installation

1. Clone the repository:
```bash
git clone https://github.com/yourusername/finvault.git
cd finvault
```

2. Install dependencies:
```bash
npm install
```

3. Start the development server:
```bash
npm run dev
```

4. Build for production:
```bash
npm run build
```

5. For deployment to GoDaddy web hosting, see [docs/godaddy-deployment.md](docs/godaddy-deployment.md)
6. For setting up server sync, see [docs/server-sync-setup.md](docs/server-sync-setup.md)

### First Steps

1. **Set Up Your Categories**: Go to Settings > Categories to create custom categories for your transactions
2. **Add Your First Transaction**: Click the "Add" button on the Transactions page to record your first income or expense
3. **Explore the Dashboard**: Watch as your financial data comes to life with visualizations and insights

### Setting Up Google Drive Integration (Optional)

If you want to sync your data across devices using Google Drive:

1. Follow the detailed instructions in [docs/google-drive-setup.md](docs/google-drive-setup.md) to set up your Google Cloud project and obtain API credentials
2. Update the application code with your credentials
3. Go to Settings > Google Drive Sync to connect your Google account
4. Select or create a folder to store your backups
5. Enable auto-sync if you want automatic backups

### Setting Up Server Sync (Optional)

If you want to store your data on your own web server for access from any device:

1. Follow the detailed instructions in [docs/server-sync-setup.md](docs/server-sync-setup.md) to set up the server-side API
2. Upload the API files to your web hosting
3. Go to Settings > Server Sync to configure the API URL
4. Enable server sync and perform the initial data upload
5. Access your data from any device by configuring the same API URL

## 💻 Technical Details

FinVault is built with modern web technologies:

- **React**: For building the user interface
- **TypeScript**: For type-safe code
- **Tailwind CSS**: For responsive and customizable styling
- **Dexie.js**: For IndexedDB database management
- **Google Drive API**: For optional cloud synchronization
- **PHP API**: For optional server-side data storage
- **Vite**: For fast development and optimized builds
- **Headless UI**: For accessible UI components
- **Lucide Icons**: For beautiful, consistent iconography

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🙏 Acknowledgements

- [Dexie.js](https://dexie.org/) for the excellent IndexedDB wrapper
- [Tailwind CSS](https://tailwindcss.com/) for the utility-first CSS framework
- [Headless UI](https://headlessui.dev/) for accessible UI components
- [Lucide Icons](https://lucide.dev/) for the beautiful icons
- [date-fns](https://date-fns.org/) for date manipulation
- All the open-source contributors whose work made this project possible
