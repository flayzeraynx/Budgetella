import React, { SelectHTMLAttributes, forwardRef } from 'react';

interface SelectProps extends SelectHTMLAttributes<HTMLSelectElement> {
  label?: string;
  error?: string;
  fullWidth?: boolean;
  options: { value: string; label: string }[];
}

const Select = forwardRef<HTMLSelectElement, SelectProps>(
  ({ label, error, fullWidth = false, options, className = '', ...props }, ref) => {
    return (
      <div className={`${fullWidth ? 'w-full' : ''} ${className}`}>
        {label && (
          <label className="block text-sm font-medium text-secondary-700 dark:text-secondary-300 mb-1">
            {label}
          </label>
        )}
        <div className="relative">
          <select
            ref={ref}
            className={`
              block w-full rounded-md border border-secondary-400 dark:border-secondary-700
              bg-white dark:bg-secondary-900 text-secondary-900 dark:text-white
              focus:outline-none focus:ring-2 focus:ring-primary-500 focus:border-primary-500
              disabled:opacity-70 disabled:cursor-not-allowed
              px-4 pr-10 py-2 text-sm appearance-none
              ${error ? 'border-red-500 focus:ring-red-500 focus:border-red-500' : ''}
            `}
            
            {...props}
          >
            {options.map((option) => (
              <option key={option.value} value={option.value}>
                {option.label}
              </option>
            ))}
          </select>
          <div className="pointer-events-none absolute inset-y-0 right-0 flex items-center px-2 text-secondary-500">
            <svg className="h-5 w-5" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor" aria-hidden="true">
              <path fillRule="evenodd" d="M5.293 7.293a1 1 0 011.414 0L10 10.586l3.293-3.293a1 1 0 111.414 1.414l-4 4a1 1 0 01-1.414 0l-4-4a1 1 0 010-1.414z" clipRule="evenodd" />
            </svg>
          </div>
        </div>
        {error && <p className="mt-1 text-sm text-red-600">{error}</p>}
      </div>
    );
  }
);

Select.displayName = 'Select';

export default Select;
