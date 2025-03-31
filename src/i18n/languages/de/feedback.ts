import { FeedbackTranslations } from '../../types';
import { feedback as enFeedback } from '../en/feedback';

export const feedback: FeedbackTranslations = {
  ...enFeedback,
  feedbackForm: 'Feedback-Formular',
  feedbackFormError: 'Beim Senden des Feedbacks ist ein Fehler aufgetreten',
  feedbackSent: 'Vielen Dank für Ihr Feedback! Wir werden uns so schnell wie möglich bei Ihnen melden.',
  feedbackError: 'Beim Senden des Feedbacks ist ein Fehler aufgetreten. Bitte versuchen Sie es später erneut.',
  name: 'Name',
  enterName: 'Geben Sie Ihren Namen ein',
  email: 'E-Mail',
  enterEmail: 'Geben Sie Ihre E-Mail-Adresse ein',
  subject: 'Betreff',
  enterSubject: 'Geben Sie einen Betreff ein',
  message: 'Nachricht',
  enterMessage: 'Geben Sie Ihre Nachricht ein',
  send: 'Senden'
};
