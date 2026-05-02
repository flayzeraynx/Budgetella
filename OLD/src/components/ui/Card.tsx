import React, { ReactNode } from 'react';

interface CardProps {
  children: ReactNode;
  className?: string;
  onClick?: () => void;
}

const Card: React.FC<CardProps> = ({ children, className = '', onClick }) => {
  return (
    <div 
      className={`bg-white dark:bg-secondary-800 rounded-lg shadow-md p-4 transition-all ${onClick ? 'cursor-pointer hover:shadow-lg' : ''} ${className}`}
      onClick={onClick}
    >
      {children}
    </div>
  );
};

export const CardHeader: React.FC<{ children: ReactNode; className?: string }> = ({ 
  children, 
  className = '' 
}) => {
  return (
    <div className={`mb-4 ${className}`}>
      {children}
    </div>
  );
};

export const CardTitle: React.FC<{ children: ReactNode; className?: string }> = ({ 
  children, 
  className = '' 
}) => {
  return (
    <h3 className={`text-lg font-semibold text-secondary-900 dark:text-white ${className}`}>
      {children}
    </h3>
  );
};

export const CardContent: React.FC<{ children: ReactNode; className?: string }> = ({ 
  children, 
  className = '' 
}) => {
  return (
    <div className={className}>
      {children}
    </div>
  );
};

export const CardFooter: React.FC<{ children: ReactNode; className?: string }> = ({ 
  children, 
  className = '' 
}) => {
  return (
    <div className={`mt-4 pt-4 border-t border-secondary-200 dark:border-secondary-700 ${className}`}>
      {children}
    </div>
  );
};

export default Card;
