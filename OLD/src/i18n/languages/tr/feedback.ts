import { FeedbackTranslations } from '../../types';
import { feedback as enFeedback } from '../en/feedback';

export const feedback: FeedbackTranslations = {
  ...enFeedback,
  feedbackForm: 'Geri Bildirim Formu',
  feedbackFormError: 'Geri bildirim gönderilirken bir hata oluştu',
  feedbackSent: 'Geri bildiriminiz için teşekkürler! En kısa sürede size geri dönüş yapacağız.',
  feedbackError: 'Geri bildirim gönderilirken bir hata oluştu. Lütfen daha sonra tekrar deneyin.',
  name: 'Ad',
  enterName: 'Adınızı girin',
  email: 'E-posta',
  enterEmail: 'E-posta adresinizi girin',
  subject: 'Konu',
  enterSubject: 'Konu girin',
  message: 'Mesaj',
  enterMessage: 'Mesajınızı girin',
  send: 'Gönder'
};
