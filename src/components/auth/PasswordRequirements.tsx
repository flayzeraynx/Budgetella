import React from 'react';
import { useTranslation } from '../../context/TranslationContext';
import { CheckCircle, XCircle } from 'lucide-react';

interface PasswordRequirementsProps {
  password: string;
}

const PasswordRequirements: React.FC<PasswordRequirementsProps> = ({ password }) => {
  const { t } = useTranslation();
  
  // Password validation rules
  const hasMinLength = password.length >= 8;
  const hasUppercase = /[A-Z]/.test(password);
  const hasLowercase = /[a-z]/.test(password);
  const hasNumber = /[0-9]/.test(password);
  const hasSpecial = /[!@#$%^&*()_+\-=\[\]{};':"\\|,.<>\/?]/.test(password);
  
  const requirements = [
    { label: t.passwordMinLength, valid: hasMinLength },
    { label: t.passwordUppercase, valid: hasUppercase },
    { label: t.passwordLowercase, valid: hasLowercase },
    { label: t.passwordNumber, valid: hasNumber },
    { label: t.passwordSpecial, valid: hasSpecial }
  ];
  
  return (
    <div className="mt-2 text-sm text-secondary-600 dark:text-secondary-400">
      <p className="font-medium mb-1">{t.passwordRequirements}</p>
      <ul className="space-y-1">
        {requirements.map((req, index) => (
          <li key={index} className="flex items-center">
            {req.valid ? (
              <CheckCircle className="w-4 h-4 mr-2 text-green-600 dark:text-green-400 flex-shrink-0" />
            ) : (
              <XCircle className="w-4 h-4 mr-2 text-secondary-400 dark:text-secondary-600 flex-shrink-0" />
            )}
            <span className={req.valid ? 'text-green-600 dark:text-green-400' : ''}>
              {req.label}
            </span>
          </li>
        ))}
      </ul>
    </div>
  );
};

export default PasswordRequirements;
