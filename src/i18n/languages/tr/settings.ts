import { SettingsTranslations } from '../../types';
import { settings as enSettings } from '../en/settings';

export const settings: SettingsTranslations = {
  ...enSettings,
  appearance: 'Görünüm',
  darkMode: 'Karanlık Mod',
  lightMode: 'Aydınlık Mod',
  systemDefault: 'Sistem Varsayılanı',
  language: 'Dil',
  currency: 'Para Birimi',
  currencyHelp: 'Tüm işlemleriniz için kullanılacak para birimini seçin',
  dataManagement: 'Veri Yönetimi',
  dataManagementDescription: 'Verilerinizi dışa aktarın, içe aktarın veya temizleyin',
  exportData: 'Verileri Dışa Aktar',
  exportDescription: 'Verilerinizi JSON veya CSV dosyası olarak indirin',
  importData: 'Verileri İçe Aktar',
  importDescription: 'Verilerinizi bir yedekleme dosyasından geri yükleyin',
  localStorageBackup: 'Yerel Depolama Yedeklemesi',
  localStorageDescription: 'Verilerinizi tarayıcınızın yerel depolamasına kaydedin veya yükleyin',
  saveToLocalStorage: 'Yerel Depolamaya Kaydet',
  loadFromLocalStorage: 'Yerel Depolamadan Yükle',
  importSuccess: 'Veriler başarıyla içe aktarıldı',
  saveSuccess: 'Veriler başarıyla kaydedildi',
  theme: 'Tema',
  themeDescription: 'Aydınlık ve karanlık mod arasında seçim yapın',
  about: 'Hakkında',
  aboutDescription: 'Budgetella, gizlilik odaklı bir kişisel finans takipçisidir. Tüm verileriniz cihazınızda yerel olarak saklanır ve hiçbir sunucuya gönderilmez.',
  version: 'Sürüm',
  storage: 'Depolama',
  storageType: 'Depolama Türü',
  privacy: 'Gizlilik',
  privacyDescription: 'Verileriniz yalnızca sizin tarafınızdan erişilebilir',
  clearData: 'Verileri Temizle',
  permanentlyDelete: 'Verilerinizi kalıcı olarak silin',
  clearAllTransactions: 'Tüm İşlemleri Temizle',
  exportOptions: 'Dışa Aktarma Seçenekleri',
  quickCsvExport: 'Hızlı CSV Dışa Aktarma',
  importOptions: 'İçe Aktarma Seçenekleri',
  quickCsvImport: 'Hızlı CSV İçe Aktarma',
  selectImportFormat: 'İçe aktarma formatını seçin',
  selectExportData: 'Dışa aktarılacak verileri seçin',
  settingsSaved: 'Ayarlar başarıyla kaydedildi',
  dataSyncSuccess: 'Veriler başarıyla senkronize edildi',
  
  // CSV Export/Import
  exportAsJSON: 'JSON Olarak Dışa Aktar',
  exportAsCSV: 'CSV Olarak Dışa Aktar',
  importJSON: 'JSON İçe Aktar',
  importCSV: 'CSV İçe Aktar',
  
  // Data Management
  dataManagementPremium: 'Veri yönetimi premium bir özelliktir. Verilerinizi dışa aktarmak, içe aktarmak veya temizlemek için premium hesaba yükseltin.'
};
